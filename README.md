# Devweeklima-terraform-aws
Demo of provisioning AWS Web Serverless Architecture

## Requerimientos de instalacion:
* Git Bash latest
* Terraform Bash latest (https://www.terraform.io/downloads.html)
* apt install zip
* AWS CLI (https://docs.aws.amazon.com/es_es/cli/latest/userguide/install-linux.html)

## Configuraciones previas
Esta demo asume que ya se tiene generado las credenciales de autenticacion al Cloud provider por lo que no tendremos una guia para ello. Para fines de la demo se usara 'Static Credentials' y la region East US 2.

* AWS Access/Secret Keys
* AWS CLI Credentialas (https://aws.amazon.com/es/premiumsupport/knowledge-center/s3-locate-credentials-error/)

## Aprovisionamiento de Infraestructura
![desired state infra](https://miro.medium.com/max/1567/1*xvgW1zovvu8eU-ZT1Dm4aA.png)
Para efectos de la demo solo se aprovisionara el AWS Lambda Function y S3

### 1. Clonar Repositorio
`
$ git clone https://github.com/czelabueno/devweeklima-terraform-aws-sample.git
`
### 2. Crear un static content JS
```bash
$ mkdir devweeklima-webapp-aws
$ cd devweeklima-webapp-aws
```
Se debe crear un archivo `main.js` que contenga el siguiente codigo:

```javascript
'use strict'

exports.handler = function(event, context, callback) {
  var response = {
    statusCode: 200,
    headers: {
      'Content-Type': 'text/html; charset=utf-8'
    },
    body: '<p>Hello world!</p>'
  }
  callback(null, response)
}
```
Comprimir el directorio en formato zip:
```bash
$ cd devweeklima-webapp-aws/
$ zip ../devweeklima-webapp-aws.zip main.js
adding: main.js (deflated 33%)
$ cd ..
```
### 3. Crear el S3 bucket para almacenar el static web content
Ir al Git repo clonado previamente y usar `terraform` para el aprovisionamiento del S3 Bucket:

```bash
$ cd ../devweeklima-terraform-aws-sample
$ terraform init
Initializing modules...

Initializing the backend...

Initializing provider plugins...

The following providers do not have any version constraints in configuration,
so the latest version was installed.

To prevent automatic upgrades to new major versions that may contain breaking
changes, it is recommended to add version = "..." constraints to the
corresponding provider blocks in configuration, with the constraint strings
suggested below.

* provider.aws: version = "~> 2.35"

Terraform has been successfully initialized!

$ terraform validate
Success! The configuration is valid.
```
Luego de validate las definiciones y los plugins, ejecutar el plan para saber la definicion y los recursos que se aprovisionaran:

```bash
$ terraform plan -var secret_key=<my_aws_secret_key>

Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.


------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # module.s3_bucket.aws_s3_bucket.bucket will be created
  + resource "aws_s3_bucket" "bucket" {
      + acceleration_status         = (known after apply)
      + acl                         = "private"
      + arn                         = (known after apply)
      + bucket                      = "devlimabucketexample"
      + bucket_domain_name          = (known after apply)
      + bucket_regional_domain_name = (known after apply)
      + force_destroy               = false
      + hosted_zone_id              = (known after apply)
      + id                          = (known after apply)
      + region                      = (known after apply)
      + request_payer               = (known after apply)
      + tags                        = {
          + "Env" = "Demo"
        }
      + website_domain              = (known after apply)
      + website_endpoint            = (known after apply)

      + versioning {
          + enabled    = true
          + mfa_delete = false
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------
```
Si el plan no genera ningun error aplicar los cambios

```bash
$ terraform apply -var secret_key=<my_aws_secret_key>

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # module.s3_bucket.aws_s3_bucket.bucket will be created
  + resource "aws_s3_bucket" "bucket" {
      + acceleration_status         = (known after apply)
      + acl                         = "private"
      + arn                         = (known after apply)
      + bucket                      = "devlimabucketexample"
      + bucket_domain_name          = (known after apply)
      + bucket_regional_domain_name = (known after apply)
      + force_destroy               = false
      + hosted_zone_id              = (known after apply)
      + id                          = (known after apply)
      + region                      = (known after apply)
      + request_payer               = (known after apply)
      + tags                        = {
          + "Env" = "Demo"
        }
      + website_domain              = (known after apply)
      + website_endpoint            = (known after apply)

      + versioning {
          + enabled    = true
          + mfa_delete = false
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

module.s3_bucket.aws_s3_bucket.bucket: Creating...
module.s3_bucket.aws_s3_bucket.bucket: Still creating... [10s elapsed]
module.s3_bucket.aws_s3_bucket.bucket: Creation complete after 14s [id=devlimabucketexample]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

```
### 4. Deploy la aplicacion usando un CI/CD tool
Solo para efectos de esta demo subire los contenidos estaticos de la aplicacion via AWS CLI al S3 Bucket. Este paso no es propio del aprovisionamiento de la infraestructura, pero se realiza para comprobar como Terraform ayuda a actualizar infraestructura de un aplicacion en el tiempo.

```bash
$ cd ..
$ aws s3 cp devweeklima-webapp-aws.zip s3://devlimabucketexample/v1.0.0/devweeklima-webapp-aws.zip
upload: ./devweeklima-webapp-aws.zip to s3://devlimabucketexample/v1.0.0/devweeklima-webapp-aws.zip
```
### 5. Actualizamos la infraestructra para agregar un Lambda Function
Usaremos un AWS Lambda functions para consumir el contenido estatico almacenado en el S3

Creamos un modulo para el Lambda Function
```bash
$cd devweeklima-terraform-aws
$mkdir lambda-function
$touch lambda_function.tf #inserta en el .tf tu codigo terraform para crear el recurso
```
Actualizamos el `main.tf` para agregar el nuevo modulo
```bash
module "lambda_function" {
  source = "./lambda-function"
}
```
Volvemos a aprovisionar el sample:

```bash
$ terraform plan -var secret_key=<my_aws_secret_key>

Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.

module.s3_bucket.aws_s3_bucket.bucket: Refreshing state... [id=devlimabucketexample]

------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # module.lambda_function.aws_iam_role.lambda_exec will be created
  + resource "aws_iam_role" "lambda_exec" {
      + arn                   = (known after apply)
      + assume_role_policy    = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = "sts:AssumeRole"
                      + Effect    = "Allow"
                      + Principal = {
                          + Service = "lambda.amazonaws.com"
                        }
                      + Sid       = ""
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + create_date           = (known after apply)
      + force_detach_policies = false
      + id                    = (known after apply)
      + max_session_duration  = 3600
      + name                  = "serverless_lambda_permissons"
      + path                  = "/"
      + unique_id             = (known after apply)
    }

  # module.lambda_function.aws_lambda_function.lambda will be created
  + resource "aws_lambda_function" "lambda" {
      + arn                            = (known after apply)
      + function_name                  = "ServerlessDevweeklima"
      + handler                        = "main.handler"
      + id                             = (known after apply)
      + invoke_arn                     = (known after apply)
      + last_modified                  = (known after apply)
      + memory_size                    = 128
      + publish                        = false
      + qualified_arn                  = (known after apply)
      + reserved_concurrent_executions = -1
      + role                           = (known after apply)
      + runtime                        = "nodejs10.x"
      + s3_bucket                      = "devlimabucketexample"
      + s3_key                         = "v1.0.0/devweeklima-webapp-aws.zip"
      + source_code_hash               = (known after apply)
      + source_code_size               = (known after apply)
      + timeout                        = 3
      + version                        = (known after apply)

      + tracing_config {
          + mode = (known after apply)
        }
    }

Plan: 2 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

$ terraform apply -var secret_key=<my_aws_secret_key>
....
module.lambda_function.aws_iam_role.lambda_exec: Creating...
module.lambda_function.aws_iam_role.lambda_exec: Creation complete after 2s [id=serverless_lambda_permissons]
module.lambda_function.aws_lambda_function.lambda: Creating...
module.lambda_function.aws_lambda_function.lambda: Still creating... [10s elapsed]
module.lambda_function.aws_lambda_function.lambda: Creation complete after 14s [id=ServerlessDevweeklima]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

```
### 6. Probamos el Lambda Function
Usamos AWS CLI para invocar al Lambda Function para probar que la aplicacion sigue funcionando.
```bash
$ aws lambda invoke --region=us-east-2 --function-name=ServerlessDevweeklima output.txt
$ cat output.txt
 {"statusCode":200,"headers":{"Content-Type":"text/html; charset=utf-8"},"body":"<p>Hello world!</p>"}
```

## Actualizacion de version de aplicacion que actualiza la definicion de infraestructura para soportarlo.

Es posible y es un escenario muy comun que la infraestructura este Live y tenga que adaptarse a cambios que la aplicacion pueda requerir. Por lo tanto es importante siempre codear las definiciones de infraestructura usanda las mismas practicas de Software.

### 1. Actualizamos el static web content y lo volvemos a cargar al S3.
Cambiamos el hello world! por un Hello DevWeekLima!

```javascript
'use strict'

exports.handler = function(event, context, callback) {
  var response = {
    statusCode: 200,
    headers: {
      'Content-Type': 'text/html; charset=utf-8'
    },
    body: '<p>Hello DevWeekLima 2019!</p>'
  }
  callback(null, response)
}
```
Lo volvemos a comprimir en formato zip reemplazando el anterior y lo subimos al S3 Bucket con un minor version superior: E.g. "1.0.1"

```bash
$ zip ../devweeklima-webapp-aws.zip main.js
updating: main.js (deflated 32%)

$ aws s3 cp devweeklima-webapp-aws.zip s3://devlimabucketexample/v1.0.1/devweeklima-webapp-aws.zip
upload: ./devweeklima-webapp-aws.zip to s3://devlimabucketexample/v1.0.1/devweeklima-webapp-aws.zip
```
### 2. Actualizamos la definicion del aprovisionamiento de la infraestructura para que Lambda soporte agregar versiones.

Editamos el `lambda_function.tf` para agregar la variable `app_version`

```terraform
variable "app_version" {}

resource "aws_lambda_function" "lambda" {
  function_name = "ServerlessDevweeklima"
  s3_bucket = "devlimabucketexample"
  s3_key = "v${var.app_version}/devweeklima-webapp-aws.zip"
  handler = "main.handler"
  runtime = "nodejs10.x"

  role = "${aws_iam_role.lambda_exec.arn}"
}
```
... con ello tenemos que actualizar el `main.tf` y el `variables.tf` para enviar la variable al modulo

```terraform
module "lambda_function" {
  source = "./lambda-function"
  app_version = "${var.app_version}"
}
```
```terraform
variable "app_version" {}
```

### 3. Ejecutamos los comandos terraform para actualizar el estado deseado final de la infraestructura

```bash
$ terraform plan
var.app_version
  Enter a value: 1.0.1
var.secret_key
  Enter a value: <my_aws_secret_key>

Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.

module.lambda_function.aws_iam_role.lambda_exec: Refreshing state... [id=serverless_lambda_permissons]
module.s3_bucket.aws_s3_bucket.bucket: Refreshing state... [id=devlimabucketexample]
module.lambda_function.aws_lambda_function.lambda: Refreshing state... [id=ServerlessDevweeklima]
.......
Plan: 0 to add, 1 to change, 0 to destroy.

------------------------------------------------------------------------
```
```bash
 $ terraform apply --auto-approve -var secret_key=<my_aws_secret_key> -var app_version=1.0.1

module.lambda_function.aws_iam_role.lambda_exec: Refreshing state... [id=serverless_lambda_permissons]
module.s3_bucket.aws_s3_bucket.bucket: Refreshing state... [id=devlimabucketexample]
module.lambda_function.aws_lambda_function.lambda: Refreshing state... [id=ServerlessDevweeklima]
module.lambda_function.aws_lambda_function.lambda: Modifying... [id=ServerlessDevweeklima]
module.lambda_function.aws_lambda_function.lambda: Modifications complete after 2s [id=ServerlessDevweeklima]

Apply complete! Resources: 0 added, 1 changed, 0 destroyed.

```
Ejecutamos nuevamente el paso 6 de la seccion anterior y debemos obtener una respuesta actualizado de la aplicacion

```bash
 {"statusCode":200,"headers":{"Content-Type":"text/html; charset=utf-8"},"body":"<p>Hola DevWeekLima 2019!</p>"}
```

## Rollback a la version anterior
Como ya se tiene terminado el desarrollo de la definicion de la insfraestructura ahora si es posible hacer el script reutilizable y podemos regresar a la version anterior:

```terraform
$terraform apply -var="app_version=1.0.0"
```

## Limpiar todo y destruir infraestructura
Tu puedes destruir todos los recursos creados con este sample usando `terraform destroy`. Esta capacidad es muy util cuando requiramos recrear ambientes o dar de baja.

---
**NOTE**
Como los S3 bucket versions se crearon con AWS CLI se deberia borrar estos primero para que terraform destruya el estado conocido de la Infraestructura. AWS puede demorar unos minutos en refrescar la eliminacion de las versiones.

---

```terraform
$ terraform destroy -var secret_key=<my_aws_secret_key> -var app_version=0.0.0


Plan: 0 to add, 0 to change, 3 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes
.....

Apply complete! Resources: 0 added, 0 changed, 3 destroyed.
```


## Author
@czelabueno
