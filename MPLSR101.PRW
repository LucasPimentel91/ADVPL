#include "protheus.ch"
#include "prtopdef.ch"
#include "rwmake.ch"
#include "topconn.ch"
#Include "totvs.ch"

//--------------------------------------------------------------------------
// Analista - Emanuel Oliveira
// Cliente  - Vitalmed
// Programa - MPLSR101 - RELATORIO DE VIDAS ATIVAS RESUMIDO
// Data     - início 29/08/24
//--------------------------------------------------------------------------

User Function MPLSR101()
    Local cCodEmp    := "    "
    Local cConEmp    := "            "
    Local cSubCon    := "         "
    Local cQuery     := ""
    Local aDados     := {}
    Local cHtml      := ""
    Local nQtdeVidas := 0
    Local nValorTotal := 0
    Local oDlg
    Local i

    // Criação da tela para entrada de dados
    DEFINE DIALOG oDlg TITLE "RELATÓRIO DE ATIVOS RESUMIDO" FROM 10,10 TO 20,40

    @ 1,1 SAY "Por favor, preencha os seguintes campos" PIXEL
    @ 6,1 SAY "para gerar o seu relatório:" PIXEL

    @ 15,2 SAY "Grupo Empresa:" SIZE 45,10
    @ 15,50 GET cCodEmp PICTURE "9999" SIZE 60,10 VALID !Empty(cCodEmp)

    @ 31,2 SAY "Contrato:" SIZE 45,10
    @ 29,50 GET cConEmp PICTURE "999999999999" SIZE 60,10 VALID !Empty(cConEmp)

    @ 48,2 SAY "Subcontrato:" SIZE 45,10
    @ 46,50 GET cSubCon PICTURE "999999999" SIZE 60,10 VALID !Empty(cSubCon)

        @ 60,50 BUTTON "Confirmar" SIZE 40, 15 PIXEL ACTION oDlg:End()
    ACTIVATE DIALOG oDlg CENTERED

    // Verificação se todos os campos foram preenchidos
    If Empty(cCodEmp) .or. Empty(cConEmp) .or. Empty(cSubCon)
        MsgStop("Todos os campos devem ser preenchidos.", "Erro")
        Return
    EndIf

    // Montagem da query SQL
    cQuery := "SELECT BA.BA1_CODINT, BA.BA1_CODEMP, BA.BA1_CODMAT, BA.BA1_NOMUSR, " + ;
              "BA.BA1_DATINC, DK.BDK_VALOR, " + ;
              "(Datediff(DD,Convert(Datetime,BA1_DATNAS,103),getdate())/365) as IDADE " + ;
              "FROM "+ RetSqlName("BA1") +" AS BA " + ;
              "INNER JOIN "+ RetSqlName("BDK") +" AS DK " + ;
              "ON BA.BA1_FILIAL = DK.BDK_FILIAL " + ;
              "AND BA.BA1_CODINT = DK.BDK_CODINT " + ;
              "AND BA.BA1_CODEMP = DK.BDK_CODEMP " + ;
              "AND BA.BA1_MATRIC = DK.BDK_MATRIC " + ;
              "AND BA.BA1_TIPREG = DK.BDK_TIPREG " + ;
              "AND DK.D_E_L_E_T_ = '' " + ;
              "WHERE BA.D_E_L_E_T_ = '' " + ;
              "AND BA.BA1_DATBLO = '' " + ;
              "AND BA.BA1_FILIAL = '" + xFilial("BA1") + "' " + ;
              "AND BA.BA1_CODEMP = '" + cCodEmp + "' " + ;
              "AND BA.BA1_CONEMP = '" + cConEmp + "' " + ;
              "AND BA.BA1_SUBCON = '" + cSubCon + "' " + ;
              "AND (Datediff(DD,Convert(Datetime,BA1_DATNAS,103),getdate())/365) " + ;
              "BETWEEN DK.BDK_IDAINI AND DK.BDK_IDAFIN"

    // Executa a consulta
    PlsQuery(cQuery, "QRY")
    
    // Selecionar a área de trabalho do resultado da consulta
    DBSELECTAREA("QRY")
    DbGoTop()

    // Processa os resultados
    While !QRY->(EOF())
        AAdd(aDados, {Field->BA1_CODMAT, Field->BA1_NOMUSR, Field->BA1_DATINC, Field->BDK_VALOR})
        nQtdeVidas++
        nValorTotal += Field->BDK_VALOR
        DbSkip()
    EndDo

    DbCloseArea()   
    // Montagem do HTML
    cHtml := "<html><head><title>Relatório de Clientes Ativos</title></head><body>"
    cHtml += "<h1>Relatório de Clientes Ativos</h1>"
    cHtml += "<h2>Filial: " + xFilial("BA1") + "</h2>"
    cHtml += "<h2>Código Empresa: " + cCodEmp + "</h2>"
    cHtml += "<h2>Contrato: " + cConEmp + "</h2>"
    cHtml += "<h2>Subcontrato: " + cSubCon + "</h2>"
    cHtml += "<p>Quantidade de Vidas Ativas: " + Alltrim(Str(nQtdeVidas)) + "</p>"
    cHtml += "<p>Valor Total: " + Transform(nValorTotal, "@E 999,999,999.99") + "</p>"
    cHtml += "<hr>"
    cHtml += "<table border='1'><tr><th>Matrícula</th><th>Nome</th><th>Data de Inclusão</th><th>Valor</th></tr>"
    
    // Loop para adicionar os dados ao HTML
    For i := 1 To Len(aDados)
        cHtml += "<tr>"
        cHtml += "<td>" + aDados[i][1] + "</td>"
        cHtml += "<td>" + aDados[i][2] + "</td>"
        cHtml += "<td>" + Dtoc(aDados[i][3]) + "</td>"
        cHtml += "<td>" + Transform(aDados[i][4], "@E 999,999,999.99") + "</td>"
        cHtml += "</tr>"
    Next i

    cHtml += "</table>"
    cHtml += "</body></html>"

    // Salva o HTML em arquivo
    MemoWrite("C:\relatorio\RelatorioClientesAtivos.html", cHtml)
    
    MsgInfo("Relatório gerado com sucesso!", "Informação")

Return
