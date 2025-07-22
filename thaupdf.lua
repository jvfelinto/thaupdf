package.path = package.path .. ";C:/Users/Pichau/AppData/Roaming/luarocks/lib/lua/5.4/?.lua"
package.cpath = package.cpath .. ";C:/Users/Pichau/AppData/Roaming/luarocks/lib/lua/5.4/?.dll"

local lfs = require "lfs"

listFile = "list.thau" -- arquivo da lista

-- main
function main()
    lfs.mkdir("pdf/")

    print("Selecione Ação:\n")
    print("search: Buscará um PDF,")
    print("tag: Adicionará uma nova tag à um PDF,")
    print("update: Atualizará o list.thau com qualquer novo PDF que estiver nele,")
    print("close: Fecha a aplicação.\n")

    local readInput = io.read("*l")

    if readInput == "search" then
        print("")
        searchPDF()
    elseif readInput == "tag" then
        print("")
        tagPDF()
    elseif readInput == "update" then
        update()
    elseif readInput == "close" then
        closeApp()
    else
        print("Comando não encontrado.\n")
        return main()
    end
end

function update() -- esta função lê os PDFs na pasta e atualiza a lista

    local nameList = getPDFList(2)
    local tagList = getPDFList(1)

    local newNameList = {}
    local newTagList = {}

    io.output("list.thau")

    --anotacao: criar meio de tirar espaços automaticamente dos nomes dos arquivos
    for file in lfs.dir("pdf/") do
        if file ~= "." and file ~= ".." then
            local check = false
            for item = 1, #nameList do
                if nameList[item] == file then
                    table.insert(newNameList, nameList[item])
                    table.insert(newTagList, tagList[item])
                    check = true
                end
            end

            if check == false then
                table.insert(newNameList, file)
                table.insert(newTagList, string.lower(file))
            end
        end
    end
    
    local content = buildListPDF(newNameList, newTagList)
    print(content)
    io.write(content)
    io.close()

    return main()
end

function buildListPDF(nameList, tagList)
    local string = [[]]
    
    if type(nameList) ~= "table" and type(tagList) ~= "table" or #nameList ~= #tagList then
        customError(2)
    end

    for i = 1, #nameList do
        string = string .. nameList[i] .. "!2" .. tagList[i] .. "\n"
    end

    return string
end

-- esta função inicia procura os pdfs em uma lista que é um arquivo separado chamado list.thau
function searchPDF()

    local list = {}

    print(
        "Escreva uma tag. Para cancelar clique enter sem escrever uma tag. Use a tag '-all' para escolher entre todos os PDFs.\n")

    local searchTag = io.read("*l")
    if searchTag == " " or searchTag == "" then
        print("Você deve inserir pelo menos 1 caractere.\n") -- erro
        return main()
    end

    if io.open(listFile, "r") then
        list = searchPDFList(searchTag)
    else
        customError(1)
    end

    if list[1] == nil then
        print("\nNão foram encontrados PDFs com esta tag.\n")
        return searchPDF()
    else
        print("\nEis os livros com esta tag:\n")
    end

    for i, name in ipairs(list) do -- printa os nomes dos pdfs
        print(tostring(i) .. ":" .. " " .. name)
    end

    print("")

    searchPDFSelect(list)

    closeApp()
end

-- esta função avança a procura dos pdfs produzindo uma lista de todos os pdfs do list.thau
function searchPDFList(searchTag)
    local selectedPDFs = {}
    local nameslist = getPDFList(2)
    local tagslist = getPDFList(1)

    if searchTag == "-all" then
        for i = 1, #nameslist do
            table.insert(selectedPDFs, nameslist[i])
        end
        return selectedPDFs
    end

    for i = 1, #tagslist do
        if string.find(tagslist[i], searchTag) then
            table.insert(selectedPDFs, nameslist[i])

        end

    end

    return selectedPDFs

end

-- esta função serve para o usuário selecionar qual pdf ele quer selecionar
function searchPDFSelect(list)

    print(
        "Selecione um dos PDFs, por seu número. Para cancelar digite '-cancelar'. Para repetir a lista de PDFs digite '-lista'.\n")
    local readInput = io.read("*l")
    if readInput == " " or readInput == "" then
        print("Você deve inserir pelo menos 1 número.\n") -- erro
        return searchPDFSelect(list)

    elseif readInput == "-cancelar" then
        return main()

    elseif readInput == "-lista" then
        for i, name in ipairs(list) do -- printa a lista
            print(tostring(i) .. ":" .. " " .. name)
        end
        print("")
        return searchPDFSelect(list)

    else
        if list[tonumber(readInput)] then -- executa o pdf
            os.execute([[start pdf/]] .. list[tonumber(readInput)])
            closeApp()
        else
            print("\nValor inválido.\n") -- erro
            return searchPDFSelect(list)
        end
    end
end

-- funcao de tag será: pega a linha, bota a tag no final
function tagPDF()
    local list = searchPDFList("-all")

    for i, name in ipairs(list) do -- printa os nomes dos pdfs
        print(tostring(i) .. ":" .. " " .. name)
    end

    print("\nSelecione um PDF dos acima, pelo número.\n")

    local book = io.read("*n")
    io.read()

    print("\nEscreva o que deseja adicionar na tag. Escreva '-cancelar' para retornar\n")

    local tag = io.read("*l")

    if tag == "-cancelar" then
        print("")
        return main()
    end

    local string = tagPDFWrite(book, tag)

    io.output("list.thau")
    io.write(string)
    io.close()

    local tagList = getPDFList(1)

    print("\nProcesso bem sucedido. Nova tag: " .. tagList[book] .. "\n")
    return main()
end

function tagPDFWrite(book, tag)
    local bookList = getPDFList(2)
    local tagList = getPDFList(1)

    tagList[book] = tagList[book] .. tag

    return buildListPDF(bookList, tagList)

end

function getPDFList(id)

    local listFileTable = {}
    local requestedTable = {}

    for book in io.lines(listFile) do
        table.insert(listFileTable, book)
    end

    if id == 0 then
        requestedTable = listFileTable

    elseif id == 1 then
        local tags = {}
        for i = 1, #listFileTable do
            local book = listFileTable[i]
            local tagStart = string.find(book, "!2")
            if tagStart ~= nil then
                local tag = string.sub(book, tagStart + 2, string.len(book))
                table.insert(tags, tag)
            end

        end
        requestedTable = tags

    elseif id == 2 then
        local names = {}
        for i = 1, #listFileTable do
            local book = listFileTable[i]
            local tagStart = string.find(book, "!2")
            if tagStart ~= nil then
                local name = string.sub(book, 1, tagStart - 1)
                table.insert(names, name)
            end

        end
        requestedTable = names

    else
        customError(3)
    end

    return requestedTable

end

function closeApp()
    os.exit()
end

function customError(id)
    local errors = {"list.thau não encontrado ou corrompido.", "list.thau está formatado incorretamente.",
                    "id errado getPDFList, o código está incorreto."}
    print(errors[id])
    return main()
end

function debugCreateList()
    io.output("list.thau")

    local content = {}

    for i = 1, 20 do
        content[i] = {
            book = "book" .. tostring(i),
            tags = "tag" .. tostring(i)
        }
        io.write("!1" .. content[i].book .. "!2" .. content[i].tags .. "\n")
    end

    io.close()

end

function debugPrintDir()
    for file in lfs.dir("pdf/") do
        if file ~= "." and file ~= ".." then
            print(file)
        end
    end
end

main()
