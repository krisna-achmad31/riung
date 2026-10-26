// Node 22, standard library only. This file is installed into the source repository.
const fs = require('node:fs');
const crypto = require('node:crypto');
const config = JSON.parse(process.env.TECHLABS_BOARD_SYNC || '{}');
const event = JSON.parse(fs.readFileSync(process.env.GITHUB_EVENT_PATH, 'utf8'));
const encode = v => ({stringValue: v});
const fields = d => Object.fromEntries(Object.entries(d).map(([k,v]) => [k, encode(v)]));
const decode = d => Object.fromEntries(Object.entries(d.fields || {}).map(([k,v]) => [k, v.stringValue]));
let token;
async function request(url, options={}) {
  const response = await fetch(url, {...options, signal: AbortSignal.timeout(30000)});
  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    const error = new Error(`HTTP ${response.status}: ${body.error?.status || body.message || 'request failed'}`);
    error.status = response.status;
    throw error;
  }
  return body;
}
const gh = route => request(`https://api.github.com/repos/${config.repository}/${route}`, {
  headers: {Authorization: `Bearer ${process.env.GITHUB_TOKEN}`, Accept:'application/vnd.github+json'}
});
const base = () => `https://firestore.googleapis.com/v1/projects/${config.firebaseProject}/databases/(default)/documents`;
const api = (route, method='GET', body) => request(`${base()}${route}`, {
  method, headers:{Authorization:`Bearer ${token}`, 'Content-Type':'application/json'},
  ...(body ? {body:JSON.stringify(body)} : {})
});
async function sync(id, branch, commit) {
  for (let attempt=0; attempt<3; attempt++) {
    let doc;
    try { doc = await api(`/tasks/${encodeURIComponent(id)}`); }
    catch (error) {
      if ([403,404].includes(error.status)) { console.log(`Skipped unavailable task ${id}`); return false; }
      throw error;
    }
    const data = decode(doc);
    if (data.projectId !== config.projectId || !['todo','in-progress'].includes(data.status)) return false;
    const updates = {status:'in-progress', branchName:branch, commitHash:commit.sha};
    const email = (commit.commit?.author?.email || '').trim().toLowerCase();
    if (!data.assignee && config.assignees?.[email]) updates.assignee = config.assignees[email];
    if (Object.entries(updates).every(([key,value]) => data[key] === value)) return false;
    const logId = crypto.createHash('sha256').update(`${id}:${branch}:${commit.sha}`).digest('hex');
    const prefix = `projects/${config.firebaseProject}/databases/(default)/documents`;
    try {
      await api(':commit', 'POST', {writes:[{
        update:{name:doc.name, fields:fields(updates)},
        updateMask:{fieldPaths:Object.keys(updates)}, currentDocument:{updateTime:doc.updateTime},
        updateTransforms:[{fieldPath:'updatedAt',setToServerValue:'REQUEST_TIME'}]
      }, {
        update:{name:`${prefix}/logs/${logId}`, fields:fields({id:logId,taskId:id,
          projectId:config.projectId,action:'github-push',actor:config.uid,
          message:`Push ${branch} (${commit.sha.slice(0,7)}) → in-progress`})},
        currentDocument:{exists:false},
        updateTransforms:[{fieldPath:'timestamp',setToServerValue:'REQUEST_TIME'}]
      }]});
      console.log(`Synced task ${id}: ${branch} ${commit.sha.slice(0,7)} → in-progress`);
      return true;
    } catch (error) {
      if (error.status === 409 && attempt < 2) continue;
      throw error;
    }
  }
}
async function main() {
  for (const key of ['apiKey','email','password','uid','firebaseProject','projectId','repository']) {
    if (!config[key]) throw new Error(`Missing sync configuration: ${key}`);
  }
  if (process.env.GITHUB_REPOSITORY !== config.repository) throw new Error('Repository scope mismatch');
  const ref = process.env.GITHUB_REF || '';
  if (!ref.startsWith('refs/heads/') || event.deleted || event.forced) return;
  const branch = ref.slice('refs/heads/'.length);
  const head = await gh(`git/ref/heads/${encodeURIComponent(branch)}`);
  if (process.env.GITHUB_EVENT_NAME === 'push' && head.object.sha !== event.after) {
    console.log('Skipped stale push; branch already has a newer head.'); return;
  }
  let commits;
  if (process.env.GITHUB_EVENT_NAME === 'workflow_dispatch') {
    const sha = event.inputs?.commit_sha || head.object.sha;
    if (!/^[0-9a-f]{40}$/.test(sha)) throw new Error('Invalid replay commit SHA');
    const comparison = await gh(`compare/${sha}...${head.object.sha}`);
    if (!['ahead','identical'].includes(comparison.status)) throw new Error('Replay commit is not on this branch');
    commits = [await gh(`commits/${sha}`)];
  } else if (/^0+$/.test(event.before || '')) {
    commits = [await gh(`commits/${event.after}`)];
  } else {
    const comparison = await gh(`compare/${event.before}...${event.after}?per_page=100`);
    if (comparison.total_commits > comparison.commits.length) throw new Error('Push exceeds 100 commits; replay the task commit manually');
    commits = comparison.commits;
  }
  const tasks = new Map();
  for (const commit of commits) {
    for (const match of (commit.commit?.message || '').matchAll(/\[task:([A-Za-z0-9_-]{1,200})\]/g)) tasks.set(match[1], commit);
  }
  if (branch.startsWith('task/')) {
    const id = branch.slice(5);
    if (/^[A-Za-z0-9_-]{1,200}$/.test(id)) tasks.set(id, await gh(`commits/${head.object.sha}`));
  }
  if (!tasks.size) { console.log('No task references in this push.'); return; }
  const session = await request(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${encodeURIComponent(config.apiKey)}`, {
    method:'POST', headers:{'Content-Type':'application/json'},
    body:JSON.stringify({email:config.email,password:config.password,returnSecureToken:true})
  });
  if (session.localId !== config.uid) throw new Error('Sync identity mismatch');
  token = session.idToken;
  let changed = 0;
  for (const [id, commit] of tasks) if (await sync(id,branch,commit)) changed++;
  console.log(`Board sync completed: ${changed} task(s) updated.`);
}
main().catch(error => {console.error(error.message);process.exitCode=1;});
