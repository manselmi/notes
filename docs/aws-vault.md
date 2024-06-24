---
tags:
  - aws
  - security
---

# aws-vault

## Project URL

[aws-vault](https://github.com/99designs/aws-vault#readme)

## Use case

I serve static content from the domain `static.manselmi.com`. Objects reside in a bucket in
`us-east-1` named `static.manselmi.com`, and objects within that bucket are accessible only via a
CloudFront distribution.

I would like to be able to do the following programatically:

* get, put and delete objects within the `static.manselmi.com` bucket

* invalidate the CloudFront cache (e.g. I just overwrote an object and want to ensure CloudFront
  doesn't serve a previously cached object)

* rotate long-term credentials

## Configuration

1. Create IAM user `manselmi-work-sts`. The user is so named because it's for my use, and will only
   be able to do anything useful by assuming a privileged role via STS.

1. Create IAM user group `work`, and assign the user `manselmi-work-sts` to the group.

1. Create IAM permission policy `static.manselmi.com` that allows the required S3 and CloudFront
   actions.

    ``` json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "ManselmiAllowS3BucketStaticManselmiCom",
                "Effect": "Allow",
                "Action": [
                    "s3:GetBucketPolicy",
                    "s3:GetBucketPolicyStatus",
                    "s3:GetBucketPublicAccessBlock",
                    "s3:GetEncryptionConfiguration",
                    "s3:ListBucket",
                    "s3:ListBucketMultipartUploads"
                ],
                "Resource": [
                    "arn:aws:s3:::static.manselmi.com"
                ]
            },
            {
                "Sid": "ManselmiAllowS3ObjectStaticManselmiCom",
                "Effect": "Allow",
                "Action": [
                    "s3:AbortMultipartUpload",
                    "s3:DeleteObject",
                    "s3:GetObject",
                    "s3:GetObjectAttributes",
                    "s3:ListMultipartUploadParts",
                    "s3:PutObject"
                ],
                "Resource": [
                    "arn:aws:s3:::static.manselmi.com/*"
                ]
            },
            {
                "Sid": "ManselmiAllowCloudfrontStaticManselmiCom",
                "Effect": "Allow",
                "Action": [
                    "cloudfront:CreateInvalidation",
                    "cloudfront:GetInvalidation",
                    "cloudfront:ListInvalidations"
                ],
                "Resource": [
                    "arn:aws:cloudfront::123456789012:distribution/ABCDEFGHIJKLMN"
                ]
            }
        ]
    }
    ```

1. Create IAM role `static.manselmi.com` and attach to it the previous permission policy. Edit the
   role's trust policy so that any user within my AWS account may assume the role, but require
   that the role's session name equal the username of the user assuming the role, and also require
   multi-factor authentication:

    ``` json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "AWS": "arn:aws:iam::123456789012:root"
                },
                "Action": "sts:AssumeRole",
                "Condition": {
                    "StringLike": {
                        "sts:RoleSessionName": "${aws:username}"
                    },
                    "Bool": {
                        "aws:MultiFactorAuthPresent": "true"
                    }
                }
            }
        ]
    }
    ```

1. Create IAM permission policy `assume-role-static.manselmi.com` that allows assuming the previous
   role:

    ``` json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "ManselmiAllowAssumeRoleStaticManselmiCom",
                "Effect": "Allow",
                "Action": [
                    "sts:AssumeRole"
                ],
                "Resource": [
                    "arn:aws:iam::123456789012:role/static.manselmi.com"
                ]
            }
        ]
    }
    ```

1. Create IAM permission policy `credential-rotation` that allows the required IAM actions:

    ``` json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "ManselmiAllowCredentialRotation",
                "Effect": "Allow",
                "Action": [
                    "iam:CreateAccessKey",
                    "iam:DeleteAccessKey",
                    "iam:GetUser"
                ],
                "Resource": [
                    "arn:aws:iam::*:user/${aws:username}"
                ]
            }
        ]
    }
    ```

1. Attach IAM permission policies `assume-role-static.manselmi.com` and `credential-rotation` to the
   IAM user group `work`.

1. Generate long-term credentials for IAM user `manselmi-work-sts` and assign to the user one or
   more MFA devices.

1. Add long-term credentials to aws-vault's storage backend:

    ``` shell
    aws-vault add manselmi
    ```

1. Update file `~/.aws/config`:

    ``` ini
    [profile manselmi]
    credential_process = /Users/manselmi/.prefix/sw/homebrew/bin/aws-vault export --format=json -- manselmi
    region = us-east-1

    [profile static.manselmi.com]
    duration_seconds = 1800
    mfa_process = /Users/manselmi/.prefix/sw/homebrew/bin/op read --no-newline op://<vault-name>/<item-name>/[section-name/]<field-name>?attribute=otp
    mfa_serial = arn:aws:iam::123456789012:mfa/1password-work
    region = us-east-1
    role_arn = arn:aws:iam::123456789012:role/static.manselmi.com
    role_session_name = manselmi-work-sts
    source_profile = manselmi
    ```

## Example usage

``` shell
aws-vault exec static.manselmi.com -- aws s3 ls s3://static.manselmi.com/security/ --recursive
```

``` text
2023-10-19 11:48:04       4369 security/gnupg/B397CE8214A7D51C1349384B140ABA5A34E6AB23.pub
2023-10-16 23:53:53       1870 security/index.html
2023-01-28 22:43:43        131 security/style.css
```

``` shell
aws-vault list
```

``` text
Profile                  Credentials              Sessions
=======                  ===========              ========
manselmi                 manselmi                 -
static.manselmi.com      -                        sts.AssumeRole:11m35s
```

``` shell
DISTRIBUTION_ID='ABCDEFGHIJKLMN'
PROFILE='static.manselmi.com'

aws-vault exec "${PROFILE}" -- aws cloudfront create-invalidation \
  --distribution-id "${DISTRIBUTION_ID}" \
  --paths '/foo' '/bar/*'
```

``` json
{
    "Location": "https://cloudfront.amazonaws.com/2020-05-31/distribution/ABCDEFGHIJKLMN/invalidation/I1PPLLBTK6DB2HF1HJMQEYO5CC",
    "Invalidation": {
        "Id": "I1PPLLBTK6DB2HF1HJMQEYO5CC",
        "Status": "InProgress",
        "CreateTime": "2023-06-26T20:22:17.518000+00:00",
        "InvalidationBatch": {
            "Paths": {
                "Quantity": 2,
                "Items": [
                    "/foo",
                    "/bar/*"
                ]
            },
            "CallerReference": "cli-1687810937-602265"
        }
    }
}
```

``` shell
INVALIDATION_ID='I1PPLLBTK6DB2HF1HJMQEYO5CC'

aws-vault exec "${PROFILE}" -- aws cloudfront get-invalidation \
  --distribution-id "${DISTRIBUTION_ID}" \
  --id "${INVALIDATION_ID}"
```

``` json
{
    "Invalidation": {
        "Id": "I1PPLLBTK6DB2HF1HJMQEYO5CC",
        "Status": "Completed",
        "CreateTime": "2023-06-26T20:22:17.518000+00:00",
        "InvalidationBatch": {
            "Paths": {
                "Quantity": 2,
                "Items": [
                    "/foo",
                    "/bar/*"
                ]
            },
            "CallerReference": "cli-1687810937-602265"
        }
    }
}
```

``` shell
# OOPS I just went out of my way to expose my long-term credentials!
aws-vault export --no-session -- manselmi
```

``` text
AWS_ACCESS_KEY_ID=AKIA…
AWS_SECRET_ACCESS_KEY=QB7h…
AWS_REGION=us-east-1
AWS_DEFAULT_REGION=us-east-1
```

``` shell
# Let's rotate them immediately…
aws-vault rotate --no-session -- manselmi
```

``` text
Rotating credentials stored for profile 'manselmi' using master credentials (takes 10-20 seconds)
Creating a new access key
Created new access key ****************LJ5Q
Deleting old access key ****************BTUC
Deleted old access key ****************BTUC
Finished rotating access key
```


<!-- vim: set ft=markdown : -->
