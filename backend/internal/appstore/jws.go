// Package appstore talks to Apple's App Store Server API and verifies the
// documents Apple signs for in-app purchases: transactions, renewal info and
// App Store Server Notifications V2 (all compact JWS, ES256, x5c chain).
package appstore

import (
	"crypto/ecdsa"
	"crypto/sha256"
	"crypto/x509"
	_ "embed"
	"encoding/asn1"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"math/big"
	"strings"
	"time"
)

// appleRootG3 is "Apple Root CA - G3" from
// https://www.apple.com/certificateauthority/AppleRootCA-G3.cer
// (SHA-256 63:34:3A:BF:B8:9A:6A:03:EB:B5:7E:9B:3F:5F:A7:BE:7C:4F:5C:75:6F:30:17:B3:A8:C4:88:C3:65:3E:91:79,
// valid until 2039-04-30). Every App Store JWS chains up to it.
//
//go:embed AppleRootCA-G3.cer
var appleRootG3 []byte

// Marker extensions Apple puts on the certificates that sign App Store data
// (the same checks as Apple's app-store-server-library).
var (
	oidLeaf         = asn1.ObjectIdentifier{1, 2, 840, 113635, 100, 6, 11, 1}
	oidIntermediate = asn1.ObjectIdentifier{1, 2, 840, 113635, 100, 6, 2, 1}
)

// ErrInvalidSignature: not a JWS signed by Apple for the App Store.
var ErrInvalidSignature = errors.New("app store: invalid signed data")

// Verifier checks App Store JWS documents against a fixed root certificate.
type Verifier struct {
	roots *x509.CertPool
	// Now is used when a document carries no signedDate.
	Now func() time.Time
}

// NewAppleVerifier trusts Apple Root CA - G3 only.
func NewAppleVerifier() *Verifier {
	v, err := NewVerifier(appleRootG3)
	if err != nil {
		panic(err) // embedded certificate; covered by tests
	}
	return v
}

// NewVerifier trusts the given DER root certificates (tests use their own).
func NewVerifier(rootsDER ...[]byte) (*Verifier, error) {
	pool := x509.NewCertPool()
	for _, der := range rootsDER {
		c, err := x509.ParseCertificate(der)
		if err != nil {
			return nil, fmt.Errorf("parse root: %w", err)
		}
		pool.AddCert(c)
	}
	return &Verifier{roots: pool, Now: time.Now}, nil
}

type jwsHeader struct {
	Alg string   `json:"alg"`
	X5C []string `json:"x5c"`
}

// Decode verifies a compact JWS and unmarshals its payload into out. The
// chain must be leaf → intermediate → our root, with Apple's marker
// extensions, valid at the document's signedDate; the ES256 signature must
// come from the leaf.
func (v *Verifier) Decode(jws string, out any) error {
	parts := strings.Split(jws, ".")
	if len(parts) != 3 {
		return fmt.Errorf("%w: not a compact JWS", ErrInvalidSignature)
	}
	var hdr jwsHeader
	if err := decodeSegment(parts[0], &hdr); err != nil {
		return fmt.Errorf("%w: header: %w", ErrInvalidSignature, err)
	}
	if hdr.Alg != "ES256" || len(hdr.X5C) != 3 {
		return fmt.Errorf("%w: want ES256 with a 3-certificate x5c", ErrInvalidSignature)
	}
	certs := make([]*x509.Certificate, len(hdr.X5C))
	for i, s := range hdr.X5C {
		der, err := base64.StdEncoding.DecodeString(s)
		if err != nil {
			return fmt.Errorf("%w: x5c[%d]: %w", ErrInvalidSignature, i, err)
		}
		if certs[i], err = x509.ParseCertificate(der); err != nil {
			return fmt.Errorf("%w: x5c[%d]: %w", ErrInvalidSignature, i, err)
		}
	}
	payload, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return fmt.Errorf("%w: payload: %w", ErrInvalidSignature, err)
	}
	var dated struct {
		SignedDate int64 `json:"signedDate"`
	}
	if err := json.Unmarshal(payload, &dated); err != nil {
		return fmt.Errorf("%w: payload: %w", ErrInvalidSignature, err)
	}
	at := v.Now()
	if dated.SignedDate > 0 {
		at = time.UnixMilli(dated.SignedDate)
	}

	leaf, intermediate := certs[0], certs[1]
	if !hasExtension(leaf, oidLeaf) || !hasExtension(intermediate, oidIntermediate) {
		return fmt.Errorf("%w: missing App Store certificate markers", ErrInvalidSignature)
	}
	inter := x509.NewCertPool()
	inter.AddCert(intermediate)
	if _, err := leaf.Verify(x509.VerifyOptions{Roots: v.roots, Intermediates: inter, CurrentTime: at,
		KeyUsages: []x509.ExtKeyUsage{x509.ExtKeyUsageAny}}); err != nil {
		return fmt.Errorf("%w: chain: %w", ErrInvalidSignature, err)
	}

	pub, ok := leaf.PublicKey.(*ecdsa.PublicKey)
	if !ok {
		return fmt.Errorf("%w: leaf key is not ECDSA", ErrInvalidSignature)
	}
	sig, err := base64.RawURLEncoding.DecodeString(parts[2])
	if err != nil || len(sig) != 64 {
		return fmt.Errorf("%w: signature encoding", ErrInvalidSignature)
	}
	digest := sha256.Sum256([]byte(parts[0] + "." + parts[1]))
	r, s := new(big.Int).SetBytes(sig[:32]), new(big.Int).SetBytes(sig[32:])
	if !ecdsa.Verify(pub, digest[:], r, s) {
		return fmt.Errorf("%w: bad signature", ErrInvalidSignature)
	}

	if err := json.Unmarshal(payload, out); err != nil {
		return fmt.Errorf("%w: payload: %w", ErrInvalidSignature, err)
	}
	return nil
}

func decodeSegment(seg string, out any) error {
	b, err := base64.RawURLEncoding.DecodeString(seg)
	if err != nil {
		return err
	}
	return json.Unmarshal(b, out)
}

func hasExtension(c *x509.Certificate, oid asn1.ObjectIdentifier) bool {
	for _, e := range c.Extensions {
		if e.Id.Equal(oid) {
			return true
		}
	}
	return false
}
