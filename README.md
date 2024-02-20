# MA163

Interface Paralela Microdigital para TK3000//e

Foi realizado uma engenharia reversa na interface paralela da Microdigital (MA163) para TK3000//e. O esquema da interface foi recriado junto com o roteamento da placa original, podendo assim ser produzido placas que funcionam como a original.

O manual original da interface digitalizado foi encontrado neste [link](http://www.apple-iigs.info/doc/fichiers/TK3000%20IIe%20Super%20parallel%20card.pdf), uma cópia do arquivo está neste repositório.

# Pastas

`Common` possui os binários das ROMs, seus *disassemblys* e uma cópia do manual original digitalizado.

Dentro da pasta [`Rev1`](Rev1) há três subpastas com os nomes `Docs`, `Eagle` e `Gerber`. O esquema elétrico em PDF, imagens, lista de materiais, etc, estão em `Docs`. Na subpasta *Eagle* há os arquivos originais para a versão 9 do software Autodesk Eagle. Para a confecção das placas há os arquivos em formato gerber na pasta `Gerber` que podem ser enviados para uma empresa de fabricação de PCBs.

# Montagem

A lista de material pode ser encontrada [aqui](Rev1/Docs/Lista%20material.md). Para facilitar a montagem abra o arquivo <a href="Rev1/Docs/ibom.html" target="_blank">ibom.html</a> localmente para visualizar os componentes e seus lugares na placa. Criado com o projeto [InteractiveHtmlBom](https://github.com/openscopeproject/InteractiveHtmlBom), linha de comando: `generate_interactive_bom --highlight-pin1 all --blacklist-empty-val MA163.brd`

Soquetes para os CIs não estão na lista de material mas são altamente recomendados para facilitar futuras manutenções.

Há a opção de usar uma rede resistiva RN1 ou usar os resistores R8 a R17 no seu lugar.

A montagem das memórias dinâmicas são opcionais. Elas são utilizadas como buffer para liberar o micro antes de terminar a impressão. Sem as memórias o micro fica "travado" até terminar a impressão. Podem ser usadas memórias 4464 para ter um buffer maior de 64KB.

# Disassembly

Foi efetuado o disassembly nas duas ROMs da interface, uma ROM é para o Apple-2 e outra ROM é para o Z80. Por enquanto não foi entendido totalmente as funções mas a maioria das coisas principais foram entendidas e comentadas. Para estes trabalhos foi utilizado a versão 6.1 Pro do software IDA da Hex-Rays.

# Observações

É recomendado a fabricação com finalização ENIG ou ouro no conector Edge para mais durabilidade.

O jumper de solda da placa não precisa ser soldado, este jumper não tem utilidade pois se mudado desabilita a saída de dados para a impressora, tornando a interface inútil!

# Curiosidades

A ROM do Apple-2 não é linear! O pino A6 desta ROM é invertido e controlado pelo Z80 e /DEVSEL, sendo assim o código que aparece para o Apple-2 muda dinamicamente. O Z80 quando escreve no endereço $5000 define o sinal FLAG_FW em 1. Quando o firmware do Apple-2 escreve em $C0xx (ativando /DEVSEL) o sinal FLAG_FW vai para 0.

O sinal FLAG_FW se em 1 faz A6 ficar invertido quando o Apple-2 acessa de $Cx00 a $Cx7F e ao acessar $Cx80 a $CxFF o sinal A6 é mantido sempre em 1. Se FLAG_FW for 0 o sinal A6 fica invertido sempre.

No TK3000//e o status da tecla MODE aparece no pino `INTIN` do slot 1. Se MODE estiver desabilitado o pino `INTIN` fica em 1.

Para a leitura de flags o Z80 utiliza o opcode `IN A,(0)`, porém a operação de I/O não é decodificada! O truque é que os sinais são forçados no barramento de dados com resistores, assim ao executar o `IN` o Z80 deixa o barramento livre e os resistores forçam o sinal que é lido corretamente. O status da tecla MODE vai no pino D5, o sinal BUSY vai no pino D6 via resistor R2 e o sinal !FLAG_FW vai no pino D7 via resistor R4.

