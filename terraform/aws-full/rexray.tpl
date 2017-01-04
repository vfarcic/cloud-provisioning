libstorage:
  service: efs
  server:
    services:
      efs:
        driver: efs
        efs:
          accessKey:      ${aws_access_key}
          secretKey:      ${aws_secret_key}
          region:         ${aws_default_region}
          securityGroups: ${aws_security_group}
          tag:            rexray
