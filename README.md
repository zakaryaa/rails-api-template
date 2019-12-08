# Rails api Templates

Quickly generate a rails api with devise and JWT authetication
using [Rails Templates](http://guides.rubyonrails.org/rails_application_templates.html).

## Usage

```bash
rails new \
  --database postgresql \
  --skip-sprockets --skip-listen --skip-javascript --skip-turbolinks --skip-test --skip-system-test --skip-webpack-install \
  --api \
  -m https://raw.githubusercontent.com/zakaryaa/rails-api-template/master/rails-api-template.rb \
  RAILS_API_NAME
```

```Curl request returns JWT token
curl --request POST \
  --url http://localhost:3000/api/v1/user/sign_in \
  --header 'content-type: application/json' \
  --data '{
"user": {
		"email": "example@domain.com",
		"password": "password"
	}
}'
```
