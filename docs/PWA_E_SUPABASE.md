# OneBus: PWA e Supabase

Guia de configuração do que **não dá para fazer só no código**.

## 1. Build do PWA

```bash
flutter build web --release --no-web-resources-cdn --pwa-strategy=none \
  --dart-define=SUPABASE_URL=https://SEU-PROJETO.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=SUA_CHAVE_ANON_PUBLICA \
  --dart-define=SITE_URL=https://SEU-DOMINIO/
```

- `--no-web-resources-cdn` leva o CanvasKit junto no build, para o app abrir
  mesmo com a conexão ruim (sem depender do CDN do Google).
- `--pwa-strategy=none` desliga o service worker padrão do Flutter. O app usa o
  próprio (`web/onebus_sw.js`), que busca primeiro na rede os arquivos
  principais e por isso não fica preso em versão antiga.
- Sem as três variáveis `--dart-define` o app roda com a **conta local** (só no
  aparelho), sem e-mail de confirmação nem recuperação de senha.
- Se publicar em um subcaminho (ex.: GitHub Pages), acrescente
  `--base-href /onebus/` e use `SITE_URL=https://usuario.github.io/onebus/`.

## 2. Hospedagem

- Precisa de **HTTPS** (exigência de PWA e do Safari).
- Sirva `onebus_sw.js` e `index.html` com `Cache-Control: no-cache` (o resto
  pode ter cache longo). O navegador já checa o service worker a cada
  abertura, mas isso evita surpresas em CDNs agressivas.
- O app usa URLs sem `#`; basta servir `index.html` na raiz (não há rotas
  profundas).

## 3. Supabase (painel do projeto)

1. **Authentication > URL Configuration**
   - **Site URL**: o mesmo valor de `SITE_URL` (ex.: `https://SEU-DOMINIO/`).
   - **Redirect URLs**: adicione `https://SEU-DOMINIO/**` e, para testes,
     `http://localhost:8090/**`.
2. **Authentication > Providers > Email**
   - Mantenha *Enable Email provider* ligado.
   - *Confirm email*: se ligado (padrão), o cadastro envia um link e o app
     avisa o usuário para confirmar antes de entrar. Se desligado, o
     cadastro já entra direto.
   - Em *Password requirements* use mínimo de **8 caracteres** (o app exige
     8+, maiúscula, minúscula, número e símbolo).
3. **Authentication > Emails (templates)**: traduza os modelos *Confirm
   signup* e *Reset password* para português. Mantenha o `{{ .ConfirmationURL }}`.
4. **SMTP próprio**: o e-mail embutido do Supabase tem limite baixo
   (poucos e-mails por hora) e é só para testes. Para produção configure um
   SMTP (Resend, SendGrid, Amazon SES…) em *Authentication > SMTP Settings*.
5. **Rate limits**: *Authentication > Rate Limits* controla as mensagens de
   "muitas tentativas".

### Como funciona a recuperação de senha

1. Em "Esqueci minha senha" o app chama `resetPasswordForEmail` com
   `redirectTo = SITE_URL`.
2. O link do e-mail abre o endereço do app com os tokens no *fragmento* da
   URL (fluxo *implicit*). Escolhido de propósito: no iPhone o link do e-mail
   abre no **Safari**, que não compartilha armazenamento com o app instalado
   na Tela de Início, e o fluxo PKCE falharia.
3. O app detecta o evento `passwordRecovery` e abre a tela **Crie uma nova
   senha**. Depois de salvar, o usuário entra com a nova senha (se instalou o
   PWA, abre pela Tela de Início).

## 4. Testar no iPhone

1. Abra o endereço no **Safari** (não no Chrome do iOS).
2. Aguarde o aviso "Instale o OneBus" (ou: Compartilhar > Adicionar à Tela de
   Início).
3. Abra pelo ícone: deve ficar em tela cheia, com a barra de status
   translúcida e nada escondido sob o notch.
4. Para ver uma atualização: publique um novo build, feche e abra o app. A
   nova versão é aplicada quando o app volta ao primeiro plano.

## 5. Checklist antes de publicar

- [ ] Variáveis `--dart-define` preenchidas no build de produção.
- [ ] URLs de redirecionamento cadastradas no Supabase.
- [ ] SMTP próprio configurado.
- [ ] Ícones conferidos (`web/icons`, gerados por
      `flutter test tool/generate_icons_test.dart`).
- [ ] Teste de cadastro, confirmação, login, "esqueci a senha" e nova senha
      com um e-mail real.
