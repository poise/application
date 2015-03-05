#
# Copyright 2015, Noah Kantrowitz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe 'git'

application '/home/app' do
  git do
    repository 'git@github.com:coderanger/private_test_repo.git'
    revision 'master'
    # Pubkey ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCk2Y0Vj3oWr5oyo2ekL0V7Tj9/vNBjH6AiO/zfIc+7dR1KaCeCkx5GRhP/XxaiSn3Fxl1JSpBswd+Oue9SJ16nuQ2eUrK5zzN+GRsz4DfqvczmDLGHrlND3FpE+GbCMbmXObYoki9LuysrYVWfye4Rc5ICm+rSqtD+QB8rUguqXKu9tVVx9ug22P5s5OxcTCOZRJsz4U++64coD8X3P++6icGemXZDUUR5B2oWoMzXafbOC1Oo0aStAxEew/kfs3hFmdfmMdC9KAilqPxY1LtqHhMB0rdqynaAc4r1HKoSbAGdcwrJgd2TV8eoB25ydvzZwnOhLdO5Cm8Od63ovEUR
    deploy_key <<-EOH
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEApNmNFY96Fq+aMqNnpC9Fe04/f7zQYx+gIjv83yHPu3UdSmgn
gpMeRkYT/18Wokp9xcZdSUqQbMHfjrnvUidep7kNnlKyuc8zfhkbM+A36r3M5gyx
h65TQ9xaRPhmwjG5lzm2KJIvS7srK2FVn8nuEXOSApvq0qrQ/kAfK1ILqlyrvbVV
cfboNtj+bOTsXEwjmUSbM+FPvuuHKA/F9z/vuonBnpl2Q1FEeQdqFqDM12n2zgtT
qNGkrQMRHsP5H7N4RZnX5jHQvSgIpaj8WNS7ah4TAdK3asp2gHOK9RyqEmwBnXMK
yYHdk1fHqAducnb82cJzoS3TuQpvDnet6LxFEQIDAQABAoIBAHkim/fB7LcK5sZb
KOePDQGk6ChXeNG+BY/igNj+IYXgc1uf2Zirvs1o5Xz8RMeQ8YcJUrduoV4pwLtC
ikfWQkoBQ66ZmlfLmE0K6eBe3PgT7KMHpNTNFsaA/5w65FfC7lvfvqllcne12+0O
ozq9ycDtKdfc9ttDRjvupnjQ212deUmpg6BG8rR9dx87Rwbk2/l+dCiSafl4HN5N
LbrENL7K3j+XVA2DKEVsrCstJzaFgqflcsnrDX76M9TEx1MtowM3Ec3jcT9W1FX1
/Rizmyow4ZV56QVz1+U13N7j0tW4EJl9EQnUye7UXyoSKfDOAGkZEKeztephBwZQ
WBgnBLkCgYEA1FmUBv7gBnVRtpfDF+qefhgT9O/ANBh0W4m6mAzawle+TleZ1vsJ
1oKG6XcSQQiRRnKdcAakxSmIw5LK54hlMczy9l5GHRQozYrbdsGUzTgYHcmThr6v
V4b7c+OxmfeV3vae07GHeXUPttzHDKXBdQqZaTaax5y8bjAflmRYNbcCgYEAxrxj
1SSwOlTXB+PVaHUPTe4AvrliCxjs9PV4O1f8oMbZ97avvNrtBNroYvukLfQNrnfF
0fIdm/BDOgAnD5I9bwbOuRqvLidzHik9KM33mpmC/4fRI5lFzMv0yd4S/dpJbGql
FQvZKGGGc8h4NXiXdSqCqr+axJdBRRL+2PJ3G3cCgYB4jZpiFlRsljIbrTDO5R2x
jE3YIjxF1xRH23sZU0LmThX2N/lYeRBuvY+F/1lXnluLWQpUTRFB9YB1N2MF6wM4
MJhGkeLQI1++wPQzCVdG4m+eiY+9UYgN8s3STxPGyy5EdFJa8FBu/aw8Lj66yWd4
4NmTR7K7XBoFnEByiukhJQKBgQCb//2NrkL3RumUM++tE1Z0IcNL81FWzLYUgyth
yetweSdYH3tLj75F9WA9crKpr82dij8qUheT9MGQodYHjw/SO1HCU4P3gtgGcPCl
OyiFnsMJup8chpAX9nGslDnsMpE4HW6AWtCXthZIhLB3qLWbL0dqqQTgFKsTgZmy
yoFceQKBgBcNNGTOjzW+J7lfC+AY+XUPhZQAUJi47+m0Tbrp5j/1BDuvI6WTlsIr
7WMFJM91xqHQZK7D0zjbGa42+uwlCs+ZBolNZpW2K7dNAriBjHuD3VDhlkqZrPC2
EwOhBYydRkzoALbgESjKP3VwfIVr9tWs4CyndY81uqRbgiRqdzR4
-----END RSA PRIVATE KEY-----
EOH
  end
end



