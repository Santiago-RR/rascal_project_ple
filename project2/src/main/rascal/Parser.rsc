module Parser

import IO;
import ParseTree;
import AST;
import SyntaxObjects;
import SyntaxExpr;
import Lexical;
import Implode; // Asumiendo que tu implode lógico sigue ahí

// Función para leer y parsear un archivo físico .ol
public AST::Module parseProgram(loc fileLoc) {
    if (!isFile(fileLoc) || fileLoc.extension != "ol") {
        throw "El archivo no existe o no tiene la extensión .ol";
    }
    str content = readFile(fileLoc);
    return parseModule(content); // Llama a la función de Implode.rsc
}