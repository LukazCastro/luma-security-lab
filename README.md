# Luma Security Lab

Laboratório prático de **SRE, DevOps e segurança de infraestrutura** com Terraform, Docker, Nginx e PostgreSQL.

> Projeto de estudo e portfólio. Os controles demonstrados são de laboratório, não uma certificação de segurança ou arquitetura pronta para produção.

## Objetivo

Aprender e demonstrar, com testes reproduzíveis, infraestrutura como código (IaC), isolamento de serviços, hardening de containers, persistência e recuperação de dados.

## Tecnologias

- Terraform (provider `kreuzwerker/docker`)
- Docker Desktop e redes bridge
- Nginx (imagem `nginx:alpine`)
- PostgreSQL 17 (imagem `postgres:17-alpine`)
- Windows / PowerShell e WSL 2
- Git

## Arquitetura atual

```text
Computador local
    |
    | http://127.0.0.1:8090
    v
Nginx (luma-security-web)
    |                     |
    | frontend            | rede privada (internal)
    v                     v
luma-frontend-network   luma-private-network
                              |
                              v
                      PostgreSQL (luma-security-db)
                              |
                              v
                      Volume luma-postgres-data
```

O Nginx participa de ambas as redes. O PostgreSQL participa apenas da rede privada e não publica a porta 5432 no host. **Ainda não há aplicação web conectada ao banco**; a comunicação verificada foi DNS/TCP, não uma integração de aplicação.

## Controles implementados

- Nginx com `read_only = true` e diretórios temporários em `tmpfs`.
- Redução das capabilities do container web.
- Porta 8090 publicada apenas em `127.0.0.1`.
- Rede privada Docker com `internal = true`.
- Volume persistente para os dados PostgreSQL com `prevent_destroy = true` na configuração Terraform.
- Senha recebida por variável sensível; arquivos `*.tfvars`, `*.tfstate` e backups excluídos do versionamento por `.gitignore`.

**Limitações:** `sensitive = true` não impede que um valor seja armazenado no Terraform State. `prevent_destroy` não substitui backup nem protege contra exclusão fora do Terraform. Este laboratório não faz gerenciamento de segredos em produção.

## Como executar

Pré-requisitos: Docker Engine em execução e Terraform instalado.

1. Copie `terraform.tfvars.example` para `terraform.tfvars` e configure uma senha forte de uso exclusivo do laboratório.
2. Na pasta do projeto, execute:

```powershell
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

3. Confirme os containers e a resposta do Nginx:

```powershell
docker ps
curl.exe -I http://localhost:8090
```

**Atenção:** `terraform apply` cria ou altera recursos Docker locais. Leia o plano antes de aprovar alterações. Evite `terraform destroy` sem avaliar cuidadosamente a persistência dos dados.

## Teste de backup e restauração do PostgreSQL

O laboratório já demonstrou:

1. Criação de backup lógico com `pg_dump` em formato customizado.
2. Cópia do arquivo de backup para a pasta local `backups/`.
3. Leitura de seu catálogo por meio de `pg_restore -l`.
4. Criação do banco separado `luma_security_restore`.
5. Restauração nesse banco usando `pg_restore --exit-on-error`.
6. Consulta de validação que retornou o registro `LUMA TECH - Teste de persistencia`.

Exemplo da consulta de verificação:

```powershell
docker exec luma-security-db psql -U luma -d luma_security_restore -c "SELECT * FROM teste_persistencia;"
```

O teste confirma a recuperação daquele registro em banco separado. **Não demonstra recuperação após perda total do servidor, nem garante RTO/RPO.**

## Próximas etapas

- Automatizar a validação e os testes da infraestrutura.
- Adicionar monitoramento, métricas e alertas (Prometheus / Grafana).
- Integrar verificação de segurança a CI/CD.
- Estudar Terraform remoto, gerenciamento de segredos e AWS.
- Simular incidentes e documentar diagnóstico, recuperação, RTO e RPO.

## Competências demonstradas

Infrastructure as Code (IaC), Terraform, Docker, Linux/containers, redes Docker, PostgreSQL, backup e restauração, validação e troubleshooting.

---

Desenvolvido como laboratório de aprendizado para evolução profissional em **Site Reliability Engineering (SRE)**.
