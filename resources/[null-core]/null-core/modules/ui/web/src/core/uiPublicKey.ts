// PUBLIC RSA key used to verify JWT tokens signed by api.null.fr
// Replace this with the contents of your `keys/ui_jwt_public.pem` after running:
//   openssl genrsa -out keys/ui_jwt_private.pem 2048
//   openssl rsa -in keys/ui_jwt_private.pem -pubout -out keys/ui_jwt_public.pem
//
// The PRIVATE key stays on api.null.fr only. This PUBLIC key being in the
// bundle is fine: it can only verify tokens, never forge them.

export const UI_JWT_PUBLIC_KEY = `-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA3Zr4AhHDNnhsTrt7Uitq
bU+6IsgggJdm0Bd91gmBOt4axsMDSy3UudMTipYvIQswf1AtAhAkF9XXt8Z0wppj
SBA0sJWiEX3ZOfV0/y1vcp0pw13LQZPqJtX+3iYTkepytrFkrVwWCfM9e09ylZKh
We9J1jqx1ercN/h2FmxVacmLnJXU5QBjyDRz7pRTYUfQR3WiWAtr628bvAfzedkI
+jcfONrdr8hzKJWopFU1zip5UDSg83Ef20SFikoiXJQJo9aAeXtsWM8Av2QCgIzE
aVWQSAW7o5S9fZp2+UxN42ONIalkH6/dGye73RJlJcHg58OYsSbGdpgL9LgHiUEJ
4wIDAQAB
-----END PUBLIC KEY-----
`;

export const UI_JWT_ISSUER = 'api.null.fr';
export const UI_JWT_AUDIENCE = 'null-ui';
export const UI_VERIFY_ENDPOINT = 'https://api.null.fr/api/licenses/verify-ui';
export const UI_REPORT_ENDPOINT = 'https://api.null.fr/api/licenses/ui-report-rejection';
