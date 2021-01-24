# Overview

At *install time*, a PKI certificate authority (CA) can either be generated for a system, or a customer can opt to supply their own (intermediate) CA. 

> Outside of a new installation, there is currently no supported method to rotate (change) the platform CA. The ability to rotate CAs is anticipated as part of a future release. 

Sealed Secrets, part of shasta-cfg, are used by the installation process to inject CA material in an encrypted form. Vault (cray-vault instance) ultimately sources and stores the CA from a K8S secret (result of decrypting the corresponding Sealed Secret).

The resulting CA will be used to sign multiple workloads on the platform (Ingress, mTLS for PostgreSQL Clusters, Spire, ...). 

> Management of Sealed Secrets should ideally take place on a secure workstation.

# Using Default Platform Generated CA

In shasta-cfg, there is a Sealed Secret generator named ```platform_ca```. By default, the ```customizations.yaml``` file will contain a generation template to use this generator, and will create a sealed secret named ```generated-platform-ca-1```. The ```cray-vault``` overrides in ```customizations.yaml``` contain a) a templated reference to expand the ```generated-platform-ca-1``` Sealed Secret and b) directives instructing vault to load the CA material on start-up -- ultimately initializing a Hashicorp Vault PKI Engine instance with the material.

> Note: the intermediate CA gets installed into Vault, not the root CA (as generated). Use of a root CA is not recommended.

The resulting default configuration (prior to seeding customizations) should look like the following ```customizations.yaml``` snippet:

```yaml
spec:
  ...
  kubernetes:
    sealed_secrets:
      ...
      gen_platform_ca_1:
        generate:
          name: generated-platform-ca-1
          data:
          - type: platform_ca
            args:
              root_days: 3651
              int_days: 3650
              root_cn: "Platform CA"
              int_cn: "Platform CA - L1"
    services:
        ...
        cray-vault:
            sealedSecrets:
            - "{{ kubernetes.sealed_secrets.gen_platform_ca_1 | toYaml }}"
            pki:
                customCA:
                    enabled: true
                    secret: generated-platform-ca-1
                    private_key: int_ca.key
                    certificate: int_ca.crt
                    ca_bundle: root_ca.crt
            ...
```

> The ```platform_ca``` generator will produce RSA CAs with a 3072-bit modulus, using SHA256 as the base signature algorithm. 

# Customize Platform Generated CA

The ```platform_ca``` generator inputs can be customized, if desired. Notably, the ```root_days```, ```int_days```, ```root_cn``` and ```int_cn``` fields can be modified. While the shasta-cfg documentation on the use of generators supplies additional detail, the ```*_days``` settings control the validity period and the ```*_cn``` settings control the common name value for the resulting CA certificates. Ensure the Sealed Secret name reference in ```spec.kubernetes.services.cray-vault.sealedSecrets``` is updated if you opt to use a different name. 

> Outside of a new installation, there is currently no supported method to rotate (change) the platform CA. Please set validity periods accordingly. The ability to rotate CAs is anticipated as part of a future release. 

# Use an External CA

The ```static_platform_ca``` generator, part of shasta-cfg, can be used to supply an external CA private key, certificate, and associated upstream CAs that form the trust chain. The generator will attempt to prevent you from supplying a root CA. You must also supply the entire trust chain up to the root CA certificate. 

> Outside of a new installation, there is currently no supported method to rotate (change) the platform CA. Please ensure validity periods are set accordingly for external CAs you use in this process. The ability to rotate CAs is anticipated as part of a future release. 

Here is an example ```customizations.yaml``` snippet illustrating the generator input to inject a static CA:

```yaml
spec:
  ...
  kubernetes:
    sealed_secrets:
      ...
      external_platform_ca_1:
        generate:
          name: external-platform-ca-1
          data:
          - type: static_platform_ca
            args:
              key: |-
                  -----BEGIN PRIVATE KEY-----
                  MIIG/gIBADANBgkqhkiG9w0BAQEFAASCBugwggbkAgEAAoIBgQDvhzXCUmGalTDo
                  uswnppXbM+E+OwU79xvaZBsiGEDPpERPZfizpSO3/6IWnYvCUCrb1V4rIhkSKGYq
                  LLVMhmEkfiEImDnx+ksbZau3/w23ogP4qj+BpbTRF707//IOfXgRSD1Q+mVQ7MVo
                  crOt8e/hR4DqZjbkWOrw9pdrfvV159o6x9RVpip33BkAtDzONYApY6ePhzS1BFmo
                  I9R0zMGNeVpy7I2m47YUwpyGAWjRoof0P2BFHX7vdEoJE/TWAlbbiqlM9OHmR85J
                  I/O0MwP63C2Eqn9HajbF1GPVw2IvGN6fE3THtmVDVwxD17cFsKxtVl8gMHljkw9V
                  I+U5piuIfDPvaCoUIC3hlv7jsQs9j52LyZZF3sOKP3xsGG4a5ThqK08EKEgrFovg
                  MYsQrt8aSx7o/7K6IzDOD9QVf7dmkFVxlbPGAjR6nlQ5aW7gFEOAr1CbbZFS+lKi
                  KGjHGraIv93MTqqToE7yRJ6Sv0yP7U9clCi6MNi89AWFfZDkLAsCAwEAAQKCAYAW
                  R61odeE+T8JM45M53PTzfs/kyfiiq0mb9tPPSBI/Pjhcak/H5gR8iPq6v8zQNkTG
                  TgKEYJeUaM2X/rCefaFrk4/fDMnXCEEUO1DNvJu6CQf1iWB+3rsC+AJSImyRjHou
                  oVmSvrfN3zg9ju3HsElv2wbSxs80TlEMOOO8zAJpBTf3X78QeHRa0c5BkoJVbASP
                  1QUxBJKSg+UTDsIkWydl0XPoXLiQXX4CUFfe3yKw3T1oKrz5sNSt0VNRpNmRToY3
                  s96Teuv2iBUnN4UciuFajgjlP0Wt2YvntWoYcwJ7mOjwo6Ru5IXdPMeLBx/xKeLF
                  j2SnPiozSAg2OV8G+yffOIcV7598s2Jh9LpgEX0S2NWPdSrjp33IWM9clivzQXaV
                  fFZtFcb3dkrXTt2jVuj6hQR5dsVMC/D/sfORPuAudejmUkAYmozTI9vgcOJpWw3h
                  AT8KBZ6xR3ifr3/GwJk9eosFMeLCTnUprhgbMzM9sde31NOzgYPhiPrN4GJRp4EC
                  gcEA+e3m7HNrSY766GOaiYwiVdzLftL7i6Ie0QTHqJLLESu2/XyxuoML6IRXc+Df
                  A/HVtuwJMqxEe3APvOcwS/Qs6qnPhh0WNz9vJ+3D/uo7Om3cbIR8J6QlsQID9Kas
                  /OAOqxcbtedkkiDSzVM1SPzNh+R85FBDK2xBM433Eu9xET0V8YZegT99SWg72l8+
                  M37/EhGvtyQpYpY8lYs8pI3Xj7IRLt+jkPKu59uDdATMvVntOMheddpTwYW7XdUI
                  M67VAoHBAPVYodD9Hoe5AcUBrahM7trGzAw3z8fom5lf/wmzJ6Mow8lgH6tliwCs
                  4NS5PR45olONhK7o7vd/PXvzP1QSIHLNbInveCH29O0ZmBasDlF/eDT+Hcdzq0sw
                  YWUR+9mX5kNS3DuZaWy6f2PDQC+mzPn1yxGmwL2yW0sY6ExfKjmFVSjqG7Mt/oMo
                  BriKaANd3ctge3aRm2MHniXOPq+jC2Zq1rRopWgWIWDzchQsyl4e6iHs5s80nQsE
                  R9nrC6CfXwKBwQDMlwLB7HmW7YRXV7HZhu1UfDnYx71CwKOZVuBaDlBM7gwN1VVn
                  6H6HCE7OfPYStJTN+MpOwNYOdd1sNZRDmM5sCjXnA0h8UWEcvnYC5ps1aVlXO9ym
                  VqjEDXJPg2F4X7GiPHhin9ikBlqJ2eN0q/1TkKbr/wf9M9Dr8vqedYOJKQgdfnE+
                  PErDHKBiUjUI0pzanb/Jm8CFA5b0k9ZAnhwndQy74jZzITYsdnVVM9il6EdYhC1P
                  LDoD4QVP+mOMa0ECgcEA0ZCKb4O1j0Kk000ysx47q53A7vLBRUVXmzOXGgbwZXpN
                  efXkNze9+q6wQKOVI/sgv3OTEQAgFkGWGAjXYA03sDftbQiiOYjC/r8s3LjMZiqW
                  V9VzREl11/yURIuO7vbDlV/yg+nvVhMa+vDtI4a7cQrVENe5rI7rUgMNcSacX5OX
                  ASKu1GcGDaujyf9XBwEnkS9xZf7LllQMbshzXPzMoQfDK0hzeKvmiPSIzdjQZoLL
                  hHzhTb3oIl/eq7IMNX/LAoHAYuVeWbSXROyXITXrYcYMwgtYjjUWThQmrLQImJjj
                  HDUNMqq8w8OaQsV+JpZ0lwukeYst3d8vH8Eb4UczUaR+oJpBeEmXjXCGYG4Ec1EQ
                  H72VrrZoJowoqORDSp88h+akcF6+vPJPuNC/Ea7+eAeiYqgxOX5nc2uLjZxBt4OC
                  AhKMY5mnBN2pfAkGVpuyUw3dqGctTSCT0jnxvFPXpldgdAmXi2NTPqPd0IzmLKNG
                  jja1TCeqn9XRTy+EArf1bYi+
                  -----END PRIVATE KEY-----
                cert: |-
                  -----BEGIN CERTIFICATE-----
                  MIIEZTCCAs2gAwIBAgIJAKnqv1FyMOp/MA0GCSqGSIb3DQEBCwUAMFsxDzANBgNV
                  BAoMBlNoYXN0YTERMA8GA1UECwwIUGxhdGZvcm0xGjAYBgNVBAMMEVJvb3QgR2Vu
                  ZXJhdGVkIENBMRkwFwYDVQQDDBBQbGF0Zm9ybSBSb290IENBMB4XDTIwMDcwMTIz
                  MjU1MVoXDTIwMDcxMTIzMjU1MVowJDEPMA0GA1UECgwGU2hhc3RhMREwDwYDVQQL
                  DAhQbGF0Zm9ybTCCAaIwDQYJKoZIhvcNAQEBBQADggGPADCCAYoCggGBAO+HNcJS
                  YZqVMOi6zCemldsz4T47BTv3G9pkGyIYQM+kRE9l+LOlI7f/ohadi8JQKtvVXisi
                  GRIoZiostUyGYSR+IQiYOfH6Sxtlq7f/DbeiA/iqP4GltNEXvTv/8g59eBFIPVD6
                  ZVDsxWhys63x7+FHgOpmNuRY6vD2l2t+9XXn2jrH1FWmKnfcGQC0PM41gCljp4+H
                  NLUEWagj1HTMwY15WnLsjabjthTCnIYBaNGih/Q/YEUdfu90SgkT9NYCVtuKqUz0
                  4eZHzkkj87QzA/rcLYSqf0dqNsXUY9XDYi8Y3p8TdMe2ZUNXDEPXtwWwrG1WXyAw
                  eWOTD1Uj5TmmK4h8M+9oKhQgLeGW/uOxCz2PnYvJlkXew4o/fGwYbhrlOGorTwQo
                  SCsWi+AxixCu3xpLHuj/srojMM4P1BV/t2aQVXGVs8YCNHqeVDlpbuAUQ4CvUJtt
                  kVL6UqIoaMcatoi/3cxOqpOgTvJEnpK/TI/tT1yUKLow2Lz0BYV9kOQsCwIDAQAB
                  o2MwYTAPBgNVHRMBAf8EBTADAQH/MA4GA1UdDwEB/wQEAwIBBjAdBgNVHQ4EFgQU
                  uNa6qcbJsHdxo6k8kaR5o53DNbIwHwYDVR0jBBgwFoAU/SFNwDBMcAYWBC2SCsDf
                  OyZJbEMwDQYJKoZIhvcNAQELBQADggGBAD8O1Vg9WLFem0RZiZWjtXiNOTZmaksE
                  +a49CE7yGqyETljlVOvbkTUTr4eJnzq2prYJUF8QavSBs38OahcxkTU2GOawZa09
                  hFc1aBiGSPAxTxJqdHV+G3QZcce1CG2e9VyrxqNudosNRNBEPMOsgg4LpvlRqMfm
                  QhPEJcfvVaCopDZBFXLBPxqmt9BckWFmTSsK09xnrCE/40YD69hdUQ6USJaz9/cd
                  UfNm0HIugRUMvFUP2ytdJmbV+1YQbfVsFrKU4aClrMg+ECX83od5N1TUNQwMePLh
                  IizLGoGDF353eRVKxlzyI724Ni9W82rMW66TQdA7vU6liItHYrhDmcZ+mK2R0F5B
                  ZuYjsLf/BCQ1uDv/bsVG40ogjH/eI/qfhRIzbgVVTF74uKG97pOakp2iQaG9USFd
                  9/s6ouQQXfkDZ2a/vzs8SBD4eIx7vmeABPRqlHTE8VzohxugxMbJNMdZRPGrEeH6
                  uddqVNpMH9ehQtsDdt0nmfVIy9/An3BKFw==
                  -----END CERTIFICATE-----
                ca_bundle: |-
                  -----BEGIN CERTIFICATE-----
                  MIIEezCCAuOgAwIBAgIJAMjuQjQKUpUtMA0GCSqGSIb3DQEBCwUAMFsxDzANBgNV
                  BAoMBlNoYXN0YTERMA8GA1UECwwIUGxhdGZvcm0xGjAYBgNVBAMMEVJvb3QgR2Vu
                  ZXJhdGVkIENBMRkwFwYDVQQDDBBQbGF0Zm9ybSBSb290IENBMB4XDTIwMDcwMTIz
                  MjU1MVoXDTIwMDcxMTIzMjU1MVowWzEPMA0GA1UECgwGU2hhc3RhMREwDwYDVQQL
                  DAhQbGF0Zm9ybTEaMBgGA1UEAwwRUm9vdCBHZW5lcmF0ZWQgQ0ExGTAXBgNVBAMM
                  EFBsYXRmb3JtIFJvb3QgQ0EwggGiMA0GCSqGSIb3DQEBAQUAA4IBjwAwggGKAoIB
                  gQDQ0DTdZmqCOfrWb8KTXJ0hT1r2G51rRE5eAp8d/PoVCgV1gg5h1+jbiv3yYd2R
                  BgM/CPZPvEJaL03wR1gO9NiGEXh1ALd8+yv1O1VRKNb6JuB5cPZFHE3Z8El6aGMc
                  zrqN1ZekRPrZMM1W5Iw78olOMZvsxYw0ZIJqfKOWYB9jYUNM1KohHVj65f/HD/Em
                  kC+9VFhepRV9z21q6fBU13bMz6/NlW19omvbTMwrVSPbYi2nSzqOfi00GXmVh/9Q
                  WElBrAeiGLOsjWkeQ8sFF8ab4SSvzLAAilyQqkBhz2jIxB4L7iG+b9KEgVLeOoMH
                  1Rs7RhduOMEQypZGVA/vsu/86/5ctM1Cu60mZP+s5B7oT2rwypz0ihLiVCaDCcS5
                  lDK7PPT5GxZPD8TAqX0SgtaxJnSB/RzavGPSS7efFvlWXh18frwlwa+FgOnyCw1/
                  qR3BHarcZX9XZivBQSupxQAaUNPMlk0N4wYi6oWrmf21zwd7NtZAinxC2F98J1sn
                  sK8CAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMCAQYwHQYD
                  VR0OBBYEFP0hTcAwTHAGFgQtkgrA3zsmSWxDMA0GCSqGSIb3DQEBCwUAA4IBgQAp
                  ApgLdQBK6fZ7CWlEWwXSKxcjv3akuSqf1NXfn/J9e1rAqqyYoTDE9DXG9dYHL9OA
                  p78KLsLy9fQmrLMmjacXw49bpXDG6XN1WLJfhgQg3j7lXvOvXyxynOgKDtBlroiU
                  nMoK+or9lF2lBIuY34GPyZCL/+vB8s1tu0dGBDgHMUL8/k5d27sdGZZUljC7CgcC
                  k+ABrv19IygDpZpZ6m5N27xajnKpJSjXOfpMCPdhCuNRMgMTX6x8bxZzVAx9ogQ8
                  16ZzAziB4iMXeCggaY/+YnoEstzTDPXB8FuqeGEVt63Y9ZA7NgWYvVExtKFGGhOL
                  lnEhCLjQyu6/LgOJNfNM9EofaE/IU+i0talgFA+ygSChmYdXzFJn4EfAY9XbwEwV
                  Pw+NHbkpv82jIpc+mopuMRdDO5OyFb+IGkn7ITUFE9N+u97oz2PjD5nQ/Z5DGjBu
                  y3sefnrlqaRanHYkmOnOBTwImPSq8RE8eJP2aRrnu+2YrnoACXxS+XWUXtNhXJ4=
                  -----END CERTIFICATE-----
    services:
        ...
        cray-vault:
            sealedSecrets:
            - "{{ kubernetes.sealed_secrets.external_platform_ca_1 | toYaml }}"
            pki:
                customCA:
                    enabled: true
                    secret: external-platform-ca-1
                    private_key: int_ca.key
                    certificate: int_ca.crt
                    ca_bundle: ca_bundle.crt
            ...
```

> Only RSA-based CAs with 3072- or 4096-bit moduli, using RSA256 as a signature/digest algorithm have been tested/are supported. Also note, the generator does not support password-protected private keys.  