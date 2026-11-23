# POSTO 17 — Modelagem manual no Blockbench

## Ambiente instalado

- Blockbench **5.2.2**, rodando pelo Linux em
  `~/Applications/Blockbench-5.2.2/AppRun`.
- Atalho **Posto 17 - Modelagem 3D** na Área de trabalho.
- Plugin `glTF Importer v1.2.1` instalado no Blockbench.
- Biblioteca **Kenney Blocky Characters 2.0**, sob licença CC0,
  em `assets3d/referencias/Kenney-Blocky-Characters/`.
- O ZIP original também fica em `assets3d/referencias/`.
- A licença é `editaveis/LICENCA-KENNEY-CC0.txt`.
- 18 variantes de personagem, modelos OBJ/FBX/GLB e animações no pacote.

## Comece por aqui

Abra no Blockbench o arquivo:

`assets3d/editaveis/P17_Humanoide_Rig_Editavel.bbmodel`

Também há um atalho separado na Área de trabalho:
**Posto 17 - Editar Personagem**.

O modelo CC0 foi adaptado a uma hierarquia de **7 grupos articulados**:
Root, Perna_Esquerda, Perna_Direita, Tronco, Braco_Esquerdo,
Braco_Direito e Cabeca. Há **6 malhas** editáveis.
Os grupos têm pivôs (pontos de rotação) de ombro, quadril e pescoço.

### Editar modelo

1. Selecione a aba **Editar**.
2. Expanda os grupos no painel Organizador à direita.
3. Clique uma malha dentro do grupo e use as ferramentas de
   movimentação/escala. Salve como projeto `.bbmodel` usando Ctrl+S.
4. O arquivo é seu para editar — sem necessidade de gerar alterações
   com IA.

### Editar animação

1. Selecione **Animar**, no canto superior direito.
2. Escolha **idle_exemplo** na lista à esquerda.
3. Escolha um grupo, como **Braco_Esquerdo**, na árvore à direita.
4. Na linha do tempo, selecione um instante e insira quadros-chave
   de Rotação com o botão **+**. Modifique os valores X/Y/Z.
5. Use o botão de reprodução (▶) para conferir o movimento.
6. Ctrl+S salva a animação com o modelo no `.bbmodel`.

O arquivo atual contém uma animação **didática**, de 2 segundos,
com 3 quadros-chave e movimento leve no braço. Não é uma animação
final aprovada para o jogo.

### Exportar para jogos 3D

Arquivo > Exportar > **Exportar como modelo glTF**.
Escolha:
- Encoding = **Binary (glb)**;
- **Export Groups as Armature** = ativado;
- **Export Animations** = ativado.

Com essas opções, o Blockbench exportou e validamos o exemplo:

`assets3d/editaveis/P17_Humanoide_Export.glb`

Comprovado pelo parser local: **6 malhas de origem, 1 esqueleto (skin),
1 animação (idle_exemplo)**. O GLB exportado está válido.

**Limite importante:** o exemplo não é um avatar Roblox R15 e
a animação não funciona automaticamente nos personagens atuais.
Para equipar no jogo será preciso importar, validar joints/mapeamento,
e adequar a hierarquia ao rig do Roblox. Nada foi publicado.

### Outras referências

- `P17_Humanoide_Base_CC0.bbmodel`: primeiro modelo simples,
  com 6 peças, antes de organizar as articulações.
- `Personagem_Base_CC0.glb`: versão de referência do pacote,
  com 10 clipes neutros. O plugin de importação não conseguiu
  converter esses clipes para a edição no teste realizado.
  O caminho comprovadamente funcional foi importar OBJ, criar grupos,
  animar no Blockbench e exportar GLB com rig e animação.

O material Kenney é CC0. A base serve para você trocar proporções,
roupas, cores, equipamentos cenográficos e movimentos manualmente.

## Desempenho

O Blockbench é mais leve que o Roblox Studio com Wine, mas usa Electron
e pode ocupar centenas de MB. Mantenha apenas Blockbench e o Desktop
Commander abertos durante a modelagem quando necessário.
O perfil `p17-lite` do PC segue ativado.

## Segurança do projeto

Nenhum arquivo de jogabilidade, personagem do Roblox, asset publicado
ou Place privado foi alterado por esta instalação. Todos os arquivos
aqui são referências locais para a sua edição e futura importação.

## Sequencia: deitado > sentado > pes para o lado > descer

Arquivo editavel: editaveis/P17_Levantar_da_Cama.bbmodel
Atalho no desktop: Posto 17 - Animação da Cama.

Duracao 5,85 s, com 9 articulacoes animadas, 13 poses de controle,
130 quadros-chave, joelhos articulados, cama de referencia e paleta
industrial neutra. Exportacao:
editaveis/P17_Levantar_da_Cama_Anim.glb

A cama nao acompanha o personagem no arquivo GLB exportado.
A integracao ao rig R15 do Roblox ainda nao foi feita.
Leia editaveis/COMO_EDITAR_ANIMACAO_CAMA.md antes de modificar.
