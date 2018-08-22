Const CONST_DECIMAL = ","

Function downloadData(Url)

	' Download data via API
	Set xmlDoc = CreateObject("Microsoft.XMLDOM")
	xmlDoc.SetProperty "SelectionLanguage", "XPath"
	xmlDoc.Async = False

	With CreateObject("MSXML2.XMLHTTP")
		.Open "GET", Url, False
		.send
		xmlDoc.LoadXML .responseText
	End With

	' Extract data from XML
	Set colNodes=xmlDoc.selectNodes("//CenaZlota")

	' Put data into array
	ReDim arrPrices(colNodes.Length-1, 1)
	i = 0
	For Each objNode in colNodes
	  arrPrices(i, 0) = objNode.ChildNodes(0).Text 
	  arrPrices(i, 1) = objNode.ChildNodes(1).Text
	  arrPrices(i, 1) = Replace(arrPrices(i, 1), ".", CONST_DECIMAL)
	  arrPrices(i, 1) = Replace(arrPrices(i, 1), ",", CONST_DECIMAL)
	  arrPrices(i, 1) = CDbl(arrPrices(i, 1))
	  i = i + 1
	Next

	downloadData = arrPrices
End Function

Function comparePrices(OldPrice, NewPrice)
	ReDim arrResults(2)
	
	diff = FormatNumber(NewPrice - OldPrice, 2)
	diff_perc = FormatPercent((NewPrice - OldPrice) / OldPrice, 2)
	comparison = Sgn(diff)
	
	arrResults(0) = comparison
	arrResults(1) = diff
	arrResults(2) = diff_perc
	
	comparePrices = arrResults
End Function


' Link parametrization
sDate1 = Year(Now()) & "-01-01"
sDate2 = Year(Now()) & "-" & Right("0" & Month(Now()), 2) & "-" & Right("0" & Day(Now()), 2)
url = "http://api.nbp.pl/api/cenyzlota/" & sDate1 & "/" & sDate2 & "?format=xml"

' Download data
arrPrices = downloadData(url)

' Compare data
n = UBound(arrPrices, 1)
' vs 1st day of the year
arrComparison1 = comparePrices(arrPrices(0,1), arrPrices(n,1)) 
' vs yesterday
arrComparison2 = comparePrices(arrPrices(n-1, 1), arrPrices(n,1)) 

' Prepare chart




msgbox arrPrices(0, 0)
msgbox arrPrices(n, 0)




strFileName = "G:\job-automation-vb-1\report.xlsx"

Set objExcel = CreateObject("Excel.Application")
objExcel.Visible = True

Set objWorkbook = objExcel.Workbooks.Add()

Set objWorksheet = objWorkbook.Worksheets(1)

objWorksheet.Cells(1,1).Resize(n+1,2) = arrPrices
objWorksheet.Cells(1,4) = arrComparison1(0)
objWorksheet.Cells(2,4) = arrComparison1(1)
objWorksheet.Cells(3,4) = arrComparison1(2)
objWorksheet.Cells(1,5) = arrComparison2(0)
objWorksheet.Cells(2,5) = arrComparison2(1)
objWorksheet.Cells(3,5) = arrComparison2(2)




Set objRange = objWorksheet.Range("$A$1:$B$162")
objRange.Select

Set objChart = objExcel.Charts
objChart.Add()
Set objScatterPlot = objChart(1)
objScatterPlot.Activate
objScatterPlot.ChartType=-4169
'objScatterPlot.ApplyDataLabels 5

objScatterPlot.PlotArea.Fill.Visible=False
objScatterPlot.PlotArea.Border.LineStyle=-4142

objScatterPlot.HasTitle = True
objScatterPlot.ChartTitle.Select
objScatterPlot.ChartTitle.Text = "Gold prices in 2018"
objScatterPlot.ChartTitle.Font.Size=20
'objScatterPlot.ChartTitle.Font.ColorIndex=4

objScatterPlot.HasLegend = False

'X axis name
objScatterPlot.Axes(xlCategory, xlPrimary).HasTitle = True
objScatterPlot.Axes(xlCategory, xlPrimary).AxisTitle.Characters.Text = "X-Axis"
'y-axis name
objScatterPlot.Axes(xlValue, xlPrimary).HasTitle = True
objScatterPlot.Axes(xlValue, xlPrimary).AxisTitle.Characters.Text = "Y-Axis" 

objWorkbook.SaveAs(strFileName)

objExcel.Quit
