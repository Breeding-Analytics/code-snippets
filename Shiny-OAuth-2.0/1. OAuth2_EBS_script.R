library(httr2)

authorize_url <- 'https://auth.ebsproject.org/oauth2/authorize'
access_url    <- 'https://auth.ebsproject.org/oauth2/token'
redirect_uri  <- 'http://localhost:1410'

# contact EBS server administrator to get these client id and secret 
client_id     <- 'xxxxxxxxxxxxxxxxxxxxxxxxx'
client_secret <- 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'


EBS_client <- httr2::oauth_client(
  id        = client_id,
  secret    = client_secret,
  token_url = access_url,
  name      = "EBS"
)

token <- httr2::oauth_flow_auth_code(
  client       = EBS_client,
  auth_url     = authorize_url,
  redirect_uri = redirect_uri
)

str(token)

QBMS::set_qbms_config(url = 'https://cbbrapi-wee.ebsproject.org', engine = 'ebs', brapi_ver = 'v2')
QBMS::set_token(token$id_token, '', token$expires_at)
QBMS::list_programs()
