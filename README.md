# OneBus

**Tudo sobre ônibus em um lugar só.**

App de transporte público para Bauru-SP: ônibus ao vivo no mapa, todos os pontos com as linhas de cada um, ponto mais próximo, notificações de chegada dos favoritos, lotação e passe. App com abas e visual iOS (materiais translúcidos, listas agrupadas e um mapa com cartão deslizante).

## Identidade

- **Logo**: o numeral "1" desenhado como uma linha de ônibus de mapa de transporte, com uma estação em cada ponta, sobre um "squircle" amarelo-placa-de-ônibus. Código em `lib/widgets/onebus_logo.dart`.
- **Wordmark**: `onebus` em Inter ExtraBold, com "bus" em tom mais claro.
- **Cores**: amarelo da marca `#FFC72C` + tinta `#141414`; o resto da interface usa as cores do sistema iOS (azul `#007AFF`, cinzas semânticos, fundos agrupados).
- **Tipografia**: Inter (a fonte aberta mais próxima da SF Pro), na escala de tamanhos da Apple.
- **Ícones do app** (web, Android e iOS) são gerados a partir da logo:
  ```
  flutter test tool/generate_icons_test.dart
  ```

## Abertura

`splash_screen.dart`: o ícone aparece com mola, a linha do "1" se desenha, um ônibus percorre a rota, as estações aparecem, e entram o nome e o slogan. Em seguida há uma transição suave para o mapa.

## Conta

- No **primeiro acesso**, depois da abertura, aparece a tela **Crie sua conta** (nome, e-mail e senha).
- A sessão fica salva: nas próximas vezes o app abre direto na Início.
- A tela de login só volta se o usuário tocar em **Sair**, na tela Conta (avatar). Por lá também dá para criar outra conta.
- A conta fica no aparelho (`services/auth_store.dart`), com a senha guardada como hash SHA-256 com salt, nunca em texto. Para ter conta em vários aparelhos, falta um backend (ex.: Firebase Auth).

## Abas

| Aba | O que tem |
|---|---|
| **Início** | No estilo Uber: mapinha ao vivo em cima (você, o ponto mais próximo, seus pontos e os ônibus das linhas favoritas) e um painel embaixo com os seus ônibus favoritos (tempo de chegada, barra de aproximação, lotação) e o ponto mais próximo |
| **Mapa** | Ônibus ao vivo e todos os pontos com as linhas de cada um (botão de camadas). O ponto mais próximo fica destacado, com um tracejado saindo da sua posição. Cartão deslizante com busca, linha, ponto e ônibus |
| **Pontos** | Todos os pontos, do mais próximo ao mais distante, com as linhas e a próxima chegada de cada uma. Tem busca, filtro por linha e estrela para favoritar. Tocar abre o ponto no mapa |
| **Passe** | Cartão no estilo Wallet, com recarga e últimas viagens |
| **Favoritos** | Linhas e pontos favoritos, combinações monitoradas e configuração das notificações |

## Notificações de chegada

Quando uma **linha favorita** está a X minutos (2, 5 ou 10) de um **ponto favorito por onde ela passa**, o OneBus avisa:

- uma **notificação do sistema** (`flutter_local_notifications`: Android, iOS, macOS, Windows, Linux e web), depois que o usuário toca em "Permitir" na aba Favoritos;
- e um **banner dentro do app**, em qualquer aba.

Cada ônibus avisa uma vez só por aproximação. Quando ele passa, o próximo volta a avisar. O sino nos pontos e o "Avisar descida" do ônibus também geram notificação.

Limitação: o aviso depende do app aberto, mesmo que em segundo plano, porque o simulador roda dentro dele. Com dados reais, o ideal é push pelo servidor (`firebase_messaging`).

## Estrutura

```
lib/
  core/theme/        cores (marca + semânticas iOS), tema claro/escuro, ThemeController
  models/            BusLine, BusStop, BusRoute
  data/
    mock_data.dart       linhas, pontos (inclui pontos de integração) e avisos
    route_geometry.dart  GERADO: rotas seguindo ruas reais (OSRM/OpenStreetMap)
  services/
    bus_simulator.dart        frota simulada: GPS, paradas, lotação, perda de sinal, previsões
    alerts_center.dart        favoritos chegando, sino, descida, relatos, banners
    notification_service.dart notificações do sistema (todas as plataformas)
    nearby.dart               pontos por distância, ponto mais próximo, minutos a pé
    favorites_store.dart      favoritos + preferências de notificação (salvos no aparelho)
  widgets/   ios.dart, glass.dart, tab_page.dart, stop_widgets.dart, bus_marker.dart, onebus_logo.dart
  screens/
    splash_screen.dart   abertura animada
    app_shell.dart       abas + barra de abas iOS + banner global
    home_tab.dart  map_home.dart  stops_tab.dart  pass_screen.dart  favorites_tab.dart
    sheet/               páginas do cartão do mapa: início/busca, linha, ponto, ônibus
    settings_sheet.dart  conta e aparência
tool/
  generate_icons_test.dart
```

## Funcionalidades vindas da pesquisa de reclamações

Pesquisamos o que os usuários criticam em Moovit, Cittamobi, Transit e similares:

| Reclamação comum | O que o OneBus faz |
|---|---|
| Previsão errada e "ônibus fantasma" (aparece no app e nunca chega) | Todo horário diz se é **ao vivo** (verde, ícone de sinal) ou **estimado** (cinza, `~`). Quando o GPS cai, o ônibus fica cinza no mapa na **última posição conhecida**, com "sem sinal há X s", em vez de seguir andando de forma inventada. |
| Não saber se o horário é real ou da tabela | Rótulo ao vivo/estimado em todas as listas, além de **saídas programadas** na tela da linha. |
| Falta de informação de lotação | Barra de lotação por ônibus e **relato colaborativo** ("Vazio / Tem lugar / Em pé / Lotado"). |
| Falta de canal de reclamação | **Reportar problema** (não passou, atraso, rampa quebrada, direção perigosa…) com protocolo. |
| Acessibilidade | Selo de **ônibus acessível** e de **ar-condicionado**. |
| Mudanças de itinerário sem aviso | **Avisos de serviço** (desvios e obras) na home, na linha e nos pontos afetados. |
| Perder o ônibus ou o ponto de descida | **Alerta de chegada** (sino: avisa quando faltam 3 min) e **aviso de descida** (avisa 1 min antes do seu ponto). |
| Excesso de anúncios | Sem anúncios. |

## Mapa ao vivo

- `flutter_map` com tiles do OpenStreetMap, dessaturados para ficarem mais calmos (estilo Apple). No modo escuro usa uma versão invertida com tom azulado.
- 12 ônibus em 4 linhas fictícias sobre ruas reais de Bauru. O movimento é interpolado entre os pings de GPS, e os ônibus diminuem quando o zoom é afastado.
- Ao abrir uma linha, o mapa enquadra a rota e esmaece as outras. Ao abrir um ponto, a câmera voa até ele. Ao abrir um ônibus, a câmera segue o veículo; arrastar o mapa interrompe.
- Por padrão a demo roda 2,5× mais rápido (`BusSimulator.speedup`).

## Próximos passos sugeridos

1. **Dados reais**: trocar `BusSimulator` por um feed GTFS-realtime, mantendo a mesma interface (`positionOf`, `eta`, `hasSignal`…).
2. **Notificações push**: hoje os alertas são banners dentro do app. Com `flutter_local_notifications` e `firebase_messaging`, eles funcionam com o app fechado.
3. **Tiles em produção**: os servidores do OpenStreetMap não são para uso em escala. Usar MapTiler, Stadia ou Mapbox com chave.
4. **Localização real**: hoje a posição do usuário é simulada (Vila Flores). Com `geolocator`, o ponto mais próximo passa a ser calculado a partir do GPS.
5. **Modo offline**: guardar favoritos e horários programados para consulta sem sinal.
