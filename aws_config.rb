#!/usr/bin/env ruby
require 'aws-sdk'

profile = ENV['AWS_PROFILE']
credentials = Aws::SharedCredentials.new(profile_name: profile)
organizations = Aws::Organizations::Client.new(region: 'us-east-1', credentials: credentials)

resp = organizations.list_accounts
accounts = resp['accounts']

while resp['next_token'] do
  resp = organizations.list_accounts({next_token: resp['next_token']})
  accounts.concat(resp['accounts'])
end

accounts.each do |account|
  # TODO: Test the role by assuming it
  # TODO: Use the assumed role to get the account alias
  if account['joined_method'] == 'CREATED'
    puts
    puts "[profile #{account['name'].delete(' ')}]"
    puts 'output = json'
    puts 'region = us-east-1'
    puts "role_arn = arn:aws:iam::#{account['id']}:role/OrganizationAccountAccessRole"
    puts "source_profile = #{profile}"
  end
end
