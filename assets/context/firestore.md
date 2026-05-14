# Firestore Structure

## usuarios

```json
{
  "email": "string",
  "funcao": "string",
  "matricula": "string",
  "nome": "string"
}
```

### Exemplo

```json
{
  "email": "fonseca.geosilva@gmail.com",
  "funcao": "coletador",
  "matricula": "0020482413095",
  "nome": "Geovanna Fonseca"
}
```

---

## produtos

```json
{
  "barcode": "string",
  "descricao": "string",
  "imagemUrl": "string",
  "marca": "string",
  "nome": "string"
}
```

### Exemplo

```json
{
  "barcode": "7891025115656",
  "descricao": "Bebida proteica - 250ml",
  "imagemUrl": "https://m.media-amazon.com/images/I/51npzHic1NL._AC_UF894,1000_QL80_.jpg",
  "marca": "Danone",
  "nome": "YoPro"
}
```

---

## dispositivos

```json
{
  "marca": "string",
  "modelo": "string",
  "serial": "string"
}
```

### Exemplo

```json
{
  "marca": "Apple",
  "modelo": "IPhone 15 Pro Max",
  "serial": "SN12345"
}
```

---

## coletas

```json
{
  "dataColeta": "string",
  "dispositivoId": "string",
  "dispositivoModelo": "string",
  "lojaId": "string",
  "lojaNome": "string",
  "preco": "double",
  "produtoBarcode": "string",
  "produtoNome": "string",
  "produtoImagemUrl": "string",
  "usuarioId": "string",
  "usuarioNome": "string"
}
```

### Exemplo

```json
{
  "dataColeta": "2024-03-20T14:30:00Z",
  "dispositivoId": "uuid_789",
  "dispositivoModelo": "IPhone 15 Pro Max",
  "lojaId": "loja_abc_456",
  "lojaNome": "Carrefour",
  "preco": 6.99,
  "produtoBarcode": "7891025115656",
  "produtoNome": "YoPro Chocolate",
  "produtoImagemUrl": "https://res.cloudinary.com/dgccbfglb/image/upload/q_auto/f_auto/v1778633476/0f07f42a-772a-4021-bdcc-5ce4b58f982b.png",
  "usuarioMatricula": "1234567",
  "usuarioNome": "João Souza"
}
```

---

## lojas

```json
{
  "ativo": "boolean",
  "cnpj": "string",
  "endereco": "string",
  "imagemUrl": "string",
  "nome": "string"
}
```

### Exemplo

```json
{
  "ativo": true,
  "cnpj": "12.345.678/0001-99",
  "endereco": "R. Marambaia, 200 - Casa Verde, São Paulo",
  "imagemUrl": "https://newtrade.com.br/wp-content/uploads/2018/09/Carrefour-fachada.jpg",
  "nome": "Carrefour"
}
```

---

# Subcoleções

## demandas - lojas/{loja_id}/demandas

```json
{
  "barcode": "string",
  "produtoDescricao": "string",
  "produtoImagemUrl": "string",
  "produtoMarca": "string",
  "produtoNome": "string",
  "status": "string"
}
```

### Exemplo

```json
{
  "barcode": "7891025115656",
  "produtoDescricao": "Bebida proteica - 250ml",
  "produtoImagemUrl": "https://...",
  "produtoMarca": "Danone",
  "produtoNome": "YoPro Chocolate",
  "status": "coletado"
}
```

---

## dispositivos_utilizados - usuarios/{usuario_id}/dispositivos_utilizados

```json
{
  "modeloDispositivo": "string",
  "serialDispositivo": "string"
}
```

### Exemplo

```json
{
  "modeloDispositivo": "IPhone 15 Pro Max",
  "serialDispositivo": "SN12345"
}
```

---

# Relacionamentos

## coletas

Relaciona:
- usuarios
- produtos
- lojas
- dispositivos

---

## demandas

Subcoleção pertencente a:
```text
lojas/{loja_id}/demandas
```

Relaciona uma loja aos produtos que devem ser coletados.

## dispositivos_utilizados

Subcoleção pertencente a:

```text
usuarios/{user_id}/dispositivos_utilizados
```

Armazena os dispositivos já utilizados por um usuário.