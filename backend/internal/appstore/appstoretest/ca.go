// Package appstoretest signs App Store-shaped JWS documents with a throw-away
// certificate chain (root → intermediate → leaf, with Apple's marker
// extensions) for tests. Never used outside tests.
package appstoretest

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/sha256"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/asn1"
	"encoding/base64"
	"encoding/json"
	"math/big"
	"testing"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/appstore"
)

// Marker extensions (see appstore.Decode).
var (
	OIDLeaf         = asn1.ObjectIdentifier{1, 2, 840, 113635, 100, 6, 11, 1}
	OIDIntermediate = asn1.ObjectIdentifier{1, 2, 840, 113635, 100, 6, 2, 1}
)

// CA is a test chain that signs like the App Store.
type CA struct {
	RootDER, IntermediateDER, LeafDER []byte
	LeafKey                           *ecdsa.PrivateKey
}

// CertOptions tweak the generated chain (to test rejections).
type CertOptions struct {
	NoLeafMarker         bool
	NoIntermediateMarker bool
	NotBefore, NotAfter  time.Time // leaf validity; zero = 2020–2040
}

// NewCA builds a valid chain.
func NewCA(t testing.TB) *CA { return NewCAWith(t, CertOptions{}) }

// NewCAWith builds a chain with options.
func NewCAWith(t testing.TB, o CertOptions) *CA {
	t.Helper()
	nb, na := time.Date(2020, 1, 1, 0, 0, 0, 0, time.UTC), time.Date(2040, 1, 1, 0, 0, 0, 0, time.UTC)
	rootKey, interKey, leafKey := newKey(t), newKey(t), newKey(t)
	root := &x509.Certificate{SerialNumber: big.NewInt(1), Subject: pkix.Name{CommonName: "Test Root"},
		NotBefore: nb, NotAfter: na, IsCA: true, BasicConstraintsValid: true, KeyUsage: x509.KeyUsageCertSign}
	rootDER := mustCreate(t, root, root, &rootKey.PublicKey, rootKey)
	rootCert, _ := x509.ParseCertificate(rootDER)

	inter := &x509.Certificate{SerialNumber: big.NewInt(2), Subject: pkix.Name{CommonName: "Test Intermediate"},
		NotBefore: nb, NotAfter: na, IsCA: true, BasicConstraintsValid: true, KeyUsage: x509.KeyUsageCertSign}
	if !o.NoIntermediateMarker {
		inter.ExtraExtensions = []pkix.Extension{{Id: OIDIntermediate, Value: []byte{0x05, 0x00}}}
	}
	interDER := mustCreate(t, inter, rootCert, &interKey.PublicKey, rootKey)
	interCert, _ := x509.ParseCertificate(interDER)

	lnb, lna := nb, na
	if !o.NotBefore.IsZero() {
		lnb, lna = o.NotBefore, o.NotAfter
	}
	leaf := &x509.Certificate{SerialNumber: big.NewInt(3), Subject: pkix.Name{CommonName: "Test StoreKit Signing"},
		NotBefore: lnb, NotAfter: lna, KeyUsage: x509.KeyUsageDigitalSignature}
	if !o.NoLeafMarker {
		leaf.ExtraExtensions = []pkix.Extension{{Id: OIDLeaf, Value: []byte{0x05, 0x00}}}
	}
	leafDER := mustCreate(t, leaf, interCert, &leafKey.PublicKey, interKey)
	return &CA{RootDER: rootDER, IntermediateDER: interDER, LeafDER: leafDER, LeafKey: leafKey}
}

// Verifier trusts only this CA's root.
func (c *CA) Verifier(t testing.TB) *appstore.Verifier {
	t.Helper()
	v, err := appstore.NewVerifier(c.RootDER)
	if err != nil {
		t.Fatal(err)
	}
	return v
}

// Sign returns payload as a compact JWS (ES256, x5c = leaf, intermediate, root).
func (c *CA) Sign(t testing.TB, payload any) string {
	t.Helper()
	enc := base64.StdEncoding.EncodeToString
	hdr, _ := json.Marshal(map[string]any{"alg": "ES256", "x5c": []string{enc(c.LeafDER), enc(c.IntermediateDER), enc(c.RootDER)}})
	body, err := json.Marshal(payload)
	if err != nil {
		t.Fatal(err)
	}
	input := base64.RawURLEncoding.EncodeToString(hdr) + "." + base64.RawURLEncoding.EncodeToString(body)
	digest := sha256.Sum256([]byte(input))
	r, s, err := ecdsa.Sign(rand.Reader, c.LeafKey, digest[:])
	if err != nil {
		t.Fatal(err)
	}
	sig := make([]byte, 64)
	r.FillBytes(sig[:32])
	s.FillBytes(sig[32:])
	return input + "." + base64.RawURLEncoding.EncodeToString(sig)
}

func newKey(t testing.TB) *ecdsa.PrivateKey {
	t.Helper()
	k, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		t.Fatal(err)
	}
	return k
}

func mustCreate(t testing.TB, tmpl, parent *x509.Certificate, pub *ecdsa.PublicKey, signer *ecdsa.PrivateKey) []byte {
	t.Helper()
	der, err := x509.CreateCertificate(rand.Reader, tmpl, parent, pub, signer)
	if err != nil {
		t.Fatal(err)
	}
	return der
}
