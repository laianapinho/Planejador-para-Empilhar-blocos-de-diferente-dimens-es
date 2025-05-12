# Planejador para o Mundo dos Blocos com Dimensões Diferentes

Este projeto implementa um planejador de meios-fins (means-ends analysis) para o clássico problema do "Mundo dos Blocos", com a particularidade de que os blocos possuem diferentes dimensões. O planejador utiliza uma representação baseada em espaços coordenados (x,y) para modelar o posicionamento dos blocos.

## Descrição

No Mundo dos Blocos tradicional, todos os blocos possuem o mesmo tamanho. Nesta implementação, os blocos podem ter tamanhos diferentes (ocupando 1, 2 ou mais posições horizontais). Isso introduz restrições adicionais ao problema:

- Blocos maiores não podem ser colocados sobre blocos menores
- Blocos devem ser posicionados de forma que tenham apoio adequado
- O planejador deve considerar o espaço disponível para cada operação

O código utiliza Prolog, uma linguagem de programação lógica adequada para problemas de planejamento e busca.

## Estrutura do Sistema

### Blocos Disponíveis
- Bloco **a**: tamanho 1
- Bloco **b**: tamanho 1
- Bloco **c**: tamanho 2
- Bloco **d**: tamanho 3

### Representação do Estado
O estado do mundo é representado através dos predicados:
- `space(X, Y, Status)`: Representa um espaço na coordenada (X,Y) com status "clear" (livre) ou "occupied(Block)" (ocupado por um bloco)
  - X: nível vertical (0 = mesa, 1 = primeiro nível, etc.)
  - Y: posição horizontal (0, 1, 2, 3, 4, 5, 6)
- `on(Block, Support)`: Indica que um bloco está sobre outro bloco ou sobre a mesa

### Ações Possíveis
A única ação disponível é `move(Block, From, To)`, que move um bloco de uma posição para outra, respeitando as restrições de tamanho e espaço.

## Como Usar

### Requisitos
- SWI-Prolog ou outro sistema Prolog compatível

### Carregando o Programa
1. Inicie o seu interpretador Prolog
2. Carregue o arquivo usando o comando:
   ```prolog
   ?- [planejador_final].
   ```

### Executando os Cenários de Teste
O programa inclui quatro cenários de teste predefinidos, cada um testando diferentes configurações iniciais e objetivos:

- **Teste 1**: Configuração básica onde blocos precisam ser empilhados
   ```prolog
   ?- test1.
   ```

- **Teste 2**: Outra configuração onde os blocos iniciam parcialmente empilhados
   ```prolog
   ?- test2.
   ```

- **Teste 3**: Configuração com um objetivo mais complexo
   ```prolog
   ?- test3.
   ```

- **Teste 4**: Configuração com objetivo desafiador que requer múltiplos movimentos
   ```prolog
   ?- test4.
   ```

Cada teste:
1. Exibe o estado inicial
2. Exibe o estado objetivo
3. Tenta encontrar um plano (sequência de movimentos)
4. Se o plano for encontrado, exibe o plano e o estado final resultante
5. Se não for possível encontrar um plano, exibe uma mensagem apropriada

### Definindo Seus Próprios Testes
Você pode definir seus próprios estados iniciais e objetivos usando a mesma estrutura dos estados predefinidos. Depois, use o predicado `plan/4` diretamente:

```prolog
?- initial_state1(Initial), my_goal_state(Goal), plan(Initial, Goal, Plan, FinalState).
```

## Detalhes da Implementação

### Planejador de Meios-Fins
O algoritmo de planejamento por meios-fins:
1. Seleciona um objetivo não satisfeito
2. Encontra uma ação que pode alcançar esse objetivo
3. Verifica se as condições para essa ação são satisfeitas no estado atual
4. Regride os objetivos com base na ação escolhida
5. Planeja recursivamente como atingir os objetivos regressados
6. Aplica a ação e planeja como atingir os objetivos restantes

### Verificação de Restrições
O planejador implementa verificações para garantir que:
- Blocos só podem ser movidos se estiverem livres (nada sobre eles)
- Um bloco só pode ser colocado sobre outro se for menor ou igual ao tamanho do bloco de suporte
- O espaço de destino deve estar livre para receber o bloco
- A física do mundo é respeitada (não há blocos flutuando)

## Licença
Este projeto está disponível sob a licença MIT.
