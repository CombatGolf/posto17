# POSTO 17 — Acordar e sair da cama

## Arquivos

- **P17_Levantar_da_Cama.bbmodel** — arquivo principal, editável no Blockbench.
- **P17_Levantar_da_Cama_Anim.glb** — personagem e animação exportados para glTF 2.0.
- **Paleta_P17_Cama.png** — atlas de cores neutras, incorporado ao .bbmodel.
- **criar_levantar_cama.py** — gerador do protótipo. NÃO execute de novo depois
  de editar manualmente o .bbmodel: ele reescreve o arquivo.
- **verificar_levantar_cama.py** — verificação dos arquivos após a exportação.

## O movimento criado (5,85 segundos)

| Tempo | Ação |
| --- | --- |
| 0 a 1 s | Deitado na cama, acordando e mexendo cabeça/braços |
| 1 a 2,1 s | Apoia-se e ergue o tronco até ficar sentado |
| 2,1 a 3,6 s | Desloca o quadril para a borda; gira as pernas para a lateral |
| 3,6 a 4,6 s | Dobra os joelhos e apoia os pés no chão |
| 4,6 a 5,85 s | Impulsiona o tronco e fica em pé ao lado da cama |

Há **13 momentos de controle, 130 quadros-chave e 9 grupos animados**.
O grupo Root tem animação de posição para fazer a transição entre
a cama e o chão sem teletransportar.

**Importante:** a cama é referência visual dentro do projeto Blockbench.
Ela não é exportada como malha do personagem GLB.

## Como modificar manualmente

1. Abra **Posto 17 - Animação da Cama** no desktop.
2. Clique em **Animar**, no canto superior direito.
3. Selecione `acordar_sentar_girar_pernas_descer`.
4. Use a linha do tempo e clique em um grupo de ossos (Root, Tronco,
   Joelho_Esquerdo etc.).
5. Edite rotação, posição e quadros-chave na interface e salve com Ctrl+S.

Para alterar o formato do corpo, clique **Editar** e escolha a malha.
Coxas/canelas, botas, cabelo e olhos são objetos separados.

## Para exportar de novo

No Blockbench:
**Arquivo > Exportar > Exportar como modelo glTF**
- Encoding: Binary (glb)
- Export Groups as Armature: marcado
- Export Animations: marcado
- Embed Textures: marcado

Salve por cima de `P17_Levantar_da_Cama_Anim.glb` (depois de
fazer uma cópia de segurança, se desejar).

Os testes anteriores confirmaram glTF 2.0 válido, 1 skin,
1 animação `acordar_sentar_girar_pernas_descer`, 10 canais
de transformação e 13 amostras ao longo dos 5,85 segundos.

## Limite na integração Roblox

O arquivo GLB gerado NÃO É um personagem R15 do Roblox. Ele usa
grupos de articulação criados no Blockbench, que ainda precisariam
ser associados a uma plataforma de personagem Roblox, com juntas
compatíveis e validação no Studio/importador. Não foi publicado no jogo.

A base vem do **Kenney Blocky Characters 2.0**, disponível sob
Creative Commons Zero (CC0); a licença está na mesma pasta.
