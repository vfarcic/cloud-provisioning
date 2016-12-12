libstorage:
  service: efs
  server:
    services:
      efs:
        driver: efs
        efs:
          accessKey:      ${aws_access_key}
          secretKey:      ${aws_secret_key}
          securityGroups: ${aws_security_group}
          region:         ${aws_default_region}
          tag:            rexray