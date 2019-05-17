grammar Lua;

@members {
   public static String grupo="<496235 558400>";
}

/*
-------------------------------------------------------------------------
Regras léxicas
-------------------------------------------------------------------------
*/
// Regra para pular fim de linha e espaços
WS
    :   (' '
    |    '\t'
    |    '\r'
    |    '\n'
    )   {skip();};

// Regra para palavras reservadas
AND : 'and';
BREAK : 'break';
DO : 'do';
ELSE : 'else';
ELSEIF : 'elseif';
END : 'end';
FALSE : 'false';
FOR : 'for';
FUNCTION : 'function';
IF : 'if';
IN : 'in';
LOCAL : 'local';
NIL : 'nil';
NOT : 'not';
OR : 'or';
REPEAT : 'repeat';
RETURN : 'return';
THEN : 'then';
TRUE : 'true';
UNTIL : 'until';
WHILE : 'while';

// Operadores
SOMA : '+';
SUB : '-';
MULT : '*';
DIV : '/';
MOD : '%';
EXP : '^';
COMP : '#';
IGUAL : '==';
DIF : '~=';
MENORIGUAL : '<=';
MAIORIGUAL : '>=';
MENOR : '<';
MAIOR : '>';
ATRI : '=';
ABREPAR : '(';
FECHAPAR : ')';
ABRECOL : '{';
FECHACOL : '}';
ABREBRACKETS : '[';
FECHABRACKETS : ']';
PONTOVIRGULA : ';';
DOISPONTOS : ':';
PONTO : '.';
DOISP : '..';
TRESP : '...';



// Regra para variáveis globais
VARIAVEISGLOBAIS : '_' ('A' .. 'Z')*;

// Regra para nomes
NOME : ('A' .. 'Z' | 'a' .. 'z') ('A' .. 'Z' | 'a' .. 'z' | '_' | '0' .. '9')*;

// Regra para cadeia de caractéres
/*
Note que estamos retirando a sequência de escape \\\
*/
CADEIA : '\'' ~('\'' | '\\')* '\''
       | '"' ~('"' | '\\')* '"';

//Regra para números
NUM : ('0' .. '9')+ ('.' ('0' .. '9')+)?;

// Regra para comentário
COMENTARIO : '-' '-' ~('\n'|'\r')* '\r'? '\n' {skip();} | '-' '-' .*? '-' '-';

/*
-------------------------------------------------------------------------
Regras do parser
-------------------------------------------------------------------------
*/
// Regra para rodar o parser
programa : trecho EOF;

trecho : (comando (';')?)* (ultimocomando (';')?)?;

bloco : trecho;

comando : listavar '=' listaexp
        | chamadadefuncao
        | 'do' bloco 'end'
        | 'while' exp 'do' bloco 'end'
        | 'repeat' bloco 'until' exp
        | 'if' exp 'then' bloco ('elseif' exp 'then' bloco)* ('else' bloco)? 'end'
        | 'for' NOME '=' exp ',' exp (',' exp)? 'do' bloco 'end'
        | 'for' listadenomes 'in' listaexp 'do' bloco 'end'
        | 'function' nomedafuncao corpodafuncao
        | 'local' 'function' NOME corpodafuncao
        | 'local' listadenomes ('=' listaexp);

ultimocomando : 'return' (listaexp)? | 'break';

nomedafuncao : NOME ('.' NOME)* (':' NOME)?{ TabelaDeSimbolos.adicionarSimbolo($NOME.text,Tipo.FUNCAO);};

listavar : var (',' var)*;

// PROBLEMA: Havia recursão não-imediata com as funções: var, expprefixo e chamadadefunção
// SOL: Copia das funções no lugar da chamada das funções

var : NOME { TabelaDeSimbolos.adicionarSimbolo($NOME.text,Tipo.VARIAVEL);}
    | expprefixo '[' exp ']' 
    | expprefixo '.' NOME { TabelaDeSimbolos.adicionarSimbolo($NOME.text,Tipo.FUNCAO);};

expprefixo :
           //Parte da var
           NOME
           | expprefixo '[' exp ']' 
           | expprefixo '.' NOME { TabelaDeSimbolos.adicionarSimbolo($NOME.text,Tipo.FUNCAO);}
           // Parte da chamadadefuncao
           | expprefixo args | expprefixo ':' NOME{ TabelaDeSimbolos.adicionarSimbolo($NOME.text,Tipo.FUNCAO);}
           | '(' exp ')';

chamadadefuncao : expprefixo args | expprefixo ':' NOME  args { TabelaDeSimbolos.adicionarSimbolo($NOME.text,Tipo.FUNCAO);};

listadenomes : NOME (',' NOME)*{ TabelaDeSimbolos.adicionarSimbolo($NOME.text,Tipo.VARIAVEL);};

listaexp : (exp ',')* exp;

exp : 'nil' | 'false' | 'true' | NUM | CADEIA | '...' | funcao | expprefixo
    | construtortabela | exp opbin exp | opunaria exp;

args : '(' (listaexp)? ')' | construtortabela | CADEIA;

funcao : 'function' corpodafuncao;

corpodafuncao : '(' (listapar)* ')' bloco 'end';

listapar : listadenomes (',' '...')? | '...';

construtortabela : '{' (listadecampos)? '}';

listadecampos : campo (separadordecampos campo)* (separadordecampos)?;

campo : '[' exp ']' '=' exp | NOME '=' exp { TabelaDeSimbolos.adicionarSimbolo($NOME.text,Tipo.VARIAVEL);} 
      | exp;

separadordecampos : ',' | ';';

opbin : '+' | '-' | '*' | '/' | '^'| '%' | '..' | '<'
      | '<=' | '>' | '>=' | '==' | '~=' | 'and' | 'or';

opunaria : '-' | 'not' | '#';