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
