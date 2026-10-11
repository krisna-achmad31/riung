// Package db embeds the SQL migrations so the single riung binary can migrate
// the database without shipping loose files.
package db

import "embed"

// Migrations holds the goose migrations under migrations/.
//
//go:embed migrations/*.sql
var Migrations embed.FS
