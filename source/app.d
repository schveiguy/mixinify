module application;

import std.stdio;
import dparse.lexer;
import std.file;

void main(string[] args)
{
    auto filedata = cast(ubyte[])read(args[1]);
    auto lexer = filedata.byToken;
    size_t lastPosOutput = 0;
    int importStart = -1;
    int importPrefix = -1;
    bool hasStd = false;
    bool foundModuleStart = false;
    foreach(token; lexer)
    {
        if(token == tok!"static" || token == tok!"public" || token == tok!"private")
        {
            if(importPrefix == -1)
                importPrefix = cast(int)token.index;
        }
        // find the module statement
        if(token == tok!"module")
        {
            foundModuleStart = true;
        }
        if(importStart != -1)
        {
            if(token == tok!"identifier" && token.text == "std")
                hasStd = true;
            if(token == tok!";")
            {
                if(hasStd)
                {
                    import std.algorithm : substitute;
                    write(cast(char[])filedata[lastPosOutput .. importStart]);
                    auto importstr = cast(char[])filedata[importStart .. token.index + 1];
                    auto filtered = importstr.substitute(" std.", " ` ~ pack ~ `.");
                    write("mixin(`", filtered, "`);");
                    lastPosOutput = token.index + 1;
                }
                importStart = -1;
            }
        }
        else if(token == tok!"import")
        {
            if(importPrefix != -1)
                importStart = importPrefix;
            else
                importStart = cast(int)token.index;
            hasStd = false;
        }
        else if(foundModuleStart && token == tok!";")
        {
            // output everything to the semicolon, then add a newline, and insert the mixin machinery
            foundModuleStart = false;
            writeln(cast(char[])filedata[lastPosOutput .. token.index + 1]);
            lastPosOutput = token.index + 1;
            writeln(`///`);
            writeln(`mixin _X!("std");`);

            // TODO: make this work
            // writeln(`mixin template _X(string pack):`);
            writeln(`mixin template _X(string pack) {`);
        }

        if(token != tok!"static" && token != tok!"public" && token != tok!"private" && token != tok!"whitespace")
        {
            importPrefix = -1;
        }
    }
    write(cast(char[])filedata[lastPosOutput .. $]);
    // close the mixin template
    // TODO: won't need this if mixin template colon is added.
    writeln("}");
}

