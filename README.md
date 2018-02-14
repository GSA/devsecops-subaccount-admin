# Admin Roles and Profiles for Organization Sub-Accounts #

## Creating Sub-Accounts ##

When you create an organization sub-account from the Console or with the
[AWS Account Broker](https://github.com/GSA/aws-account-broker) it automatically
creates an IAM role called `OrganizationAccountAccessRole`.  The Terraform code
to create this is:

```
resource "aws_iam_role" "OrganizationAccountAccessRole" {
  name = "OrganizationAccountAccessRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "arn:aws:iam::${var.mgmt_account}:root"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
```

This role has an inline `AdministratorAccess` policy:

```
resource "aws_iam_policy" "AdministratorAccess" {
  name        = "AdministratorAccess"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "*",
            "Resource": "*"
        }
    ]
}
EOF
}
```

## Admin Role in Management Account ##

In the management account, you need an IAM policy to allow administrators to
assume the `OrganizationAccountAccessRole` in the tenant accounts.  The policy
is defined by the following Terraform code:

```
resource "aws_iam_policy" "org-account-access" {
  name        = "org-account-access"

  policy = <<EOF
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Sid": "",
              "Effect": "Allow",
              "Action": [
                  "sts:AssumeRole"
              ],
              "Resource": [
                  "arn:aws:iam::*:role/OrganizationAccountAccessRole"
              ]
          }
      ]
  }
EOF
}
```

## AWS Shared Credentials ##

In your `~/.aws/credentials` file, you will need to put your access and secret
keys for the management account:

```
[mgmt_account]
aws_access_key_id = XXXXXXXXXXXXXXXXXXXX
aws_secret_access_key = xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

In your `~/.aws/config` file add the following for each sub account:

```
[profile subaccount]
output = json
region = us-east-1
role_arn = arn:aws:iam::111111111111:role/OrganizationAccountAccessRole
source_profile = mgmt_account
```

Note the subaccounts need to have unique names, I recommend using the account
alias if set (`aws iam list-account-aliases`).

### Ruby Script ###

The ruby script `aws_config.rb` will write to STDOUT the above config profile
settings for each created account. (Requires `aws-sdk` v2)

```
export AWS_PROFILE=mgmt_account
ruby aws_config.rb >> ~/.aws/aws_config.rb
```
