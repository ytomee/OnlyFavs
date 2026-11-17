# API de perfil para implementar no OutSystems

O GET já está publicado no OutSystems. O Flutter está preparado para o PUT
`/Profile/Update` descrito abaixo, que ainda precisa de ser criado no OutSystems.

Base URL: `https://personal-ctmif2sq.outsystemscloud.com/OnlyFavs/rest`

## Consultar o perfil

`GET /Profile/Get?Id=7`

Entrada: `Id`, do tipo Integer/Identifier, enviado na query string do URL.
O GET não envia body. Os pedidos de criação e edição enviam os dados no body JSON.
O ID devolvido pelo login é guardado no dispositivo com a sessão e recuperado
ao reabrir a aplicação. `AuthService.sessionUserId` lê esse ID; o separador
Perfil passa-o diretamente ao GET. Não existe um ID fixo para a consulta.
Para o próprio perfil, `Id` é o ID da sessão; para consultar outro perfil,
é o ID desse utilizador. Nome, username, biografia, visibilidade e contadores
vêm desta resposta, sem usar os dados guardados na sessão. A página recebe
separadamente o ID da sessão e só apresenta Editar, Partilhar e Configurar
acesso e preços quando os dois IDs são iguais.

Resposta HTTP 200, com `ProfileInfo` e `Message` ao mesmo nível:

```json
{
  "ProfileInfo": {
    "Id": 7,
    "Name": "Maria Pinto",
    "Username": "maria",
    "Biography": "Crio e partilho os meus pequenos momentos.",
    "IsPublic": true,
    "PublicationCount": 32,
    "PhotoCount": 18,
    "VideoCount": 9
  },
  "Message": ""
}
```

`Message` é Text: fica vazia no sucesso e contém a explicação em caso de erro.
`Id`, `Name` e `Username` são obrigatórios no sucesso. Os restantes campos
podem estar ausentes ou ser `null`; o Flutter usa os valores por defeito abaixo:

| Atributo | Tipo no OutSystems | Utilização |
| --- | --- | --- |
| `Id` | Integer/Identifier | ID do utilizador consultado |
| `Name` | Text | Nome apresentado e editável |
| `Username` | Text | Username apresentado e editável, sem `@` |
| `Biography` | Text | Biografia editável; por defeito `""` |
| `IsPublic` | Boolean | Mostra perfil público ou privado; por defeito `false` |
| `PublicationCount` | Integer | Total de publicações, maior ou igual a zero; por defeito `0` |
| `PhotoCount` | Integer | Total de fotografias, maior ou igual a zero; por defeito `0` |
| `VideoCount` | Integer | Total de vídeos, maior ou igual a zero; por defeito `0` |

O `Id` da resposta confirma que o perfil recebido corresponde ao ID pedido.
O cliente atual precisa deste atributo, inclusive para a edição. Em caso de
erro não é necessário devolver um ID: `ProfileInfo` pode ser `null`.

Exemplo de erro na consulta (HTTP 404):

```json
{
  "ProfileInfo": null,
  "Message": "Utilizador não encontrado."
}
```

O Flutter apresenta a `Message` do servidor. Se o OutSystems devolver HTTP 200
com `ProfileInfo` vazio, ausente ou com `Id: 0`, a resposta também é tratada como erro
e essa mensagem é apresentada. `Success: false` continua a ser aceite, mas
não é necessário acrescentá-lo à estrutura acima.

## Editar o perfil

`PUT /Profile/Update`

Ao abrir Editar perfil, o Flutter faz novamente `GET /Profile/Get?Id=...` e
preenche o formulário com o `ProfileInfo` atual do servidor. Nome, username e
biografia não são lidos da sessão; a sessão fornece apenas o ID.

Cabeçalhos: `Content-Type: application/json` e `Accept: application/json`.

Body de entrada:

```json
{
  "SessionUserId": 7,
  "Id": 7,
  "Name": "Maria Pinto",
  "Username": "maria",
  "Biography": "A minha nova biografia."
}
```

`SessionUserId` é o ID do utilizador da sessão e `Id` é o ID do perfil que se
pretende editar. Ambos são Integer/Identifier.

Antes de guardar, o OutSystems deve confirmar que `SessionUserId` é igual a
`Id`. Se forem diferentes, devolver HTTP 403 com uma mensagem e não alterar
dados. O Flutter também bloqueia a gravação quando os IDs são diferentes.

Atualizar apenas `Name`, `Username` e `Biography` do utilizador com esse ID.
O Flutter retira espaços no início/fim e o `@` inicial do username. Nome e
username são obrigatórios; a biografia pode ficar vazia. O username não pode ter
espaços e o OutSystems deve validar que é único antes de guardar.

Devolver HTTP 200 com a mesma estrutura `ProfileInfo` completa da consulta, já com os
dados guardados, com `Message: ""`. O perfil passa a mostrar os valores dessa
resposta. Não devolver
uma resposta vazia/204: o cliente precisa dos dados confirmados pelo servidor.

No OutSystems, podes reutilizar a estrutura `ProfileResponse` do GET na saída
do PUT: `ProfileInfo` e `Message`. Depois de validar os IDs e guardar os três
campos, consulta os dados atualizados para preencher essa resposta.

Cancelar ou voltar não faz PUT. Em caso de erro ao guardar, a mensagem da API
é apresentada e o formulário mantém os valores introduzidos para nova tentativa.

## Erros

Usar HTTP 400 para dados inválidos, 403 para tentar editar outro utilizador,
404 para utilizador inexistente e 409 para username já utilizado.
Em qualquer erro, devolver:

```json
{
  "Message": "Este username já está a ser utilizado."
}
```

O Flutter também aceita `{"Success": false, "Message": "..."}` com HTTP 200,
caso seja necessário seguir esse formato no OutSystems.

## Imagens e outros dados

Foto default: `assets/images/user.jpg`. Banner default:
`assets/images/banner.jpg`. As imagens são locais e não entram nos pedidos.
Não são necessários atributos de imagem, email, password ou preços nesta API.
Os contadores e a visibilidade são apenas de leitura nesta página de edição.
A listagem das publicações continua por implementar e não faz parte destes
dois endpoints.
