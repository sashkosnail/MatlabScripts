function deleteExcelSheets(excel_file, sheet_names)
Excel = actxserver('Excel.Application'); 
[~, sheet_names] = xlsfinfo(excel_file);
set(Excel, 'Visible', 0);
set(Excel,'DisplayAlerts',0);
Workbooks = Excel.Workbooks; 
Workbook = Workbooks.Open(excel_file);
Sheets = Excel.ActiveWorkBook.Sheets;
for sheet=sheet_names
    if(ismember(sheet, sheet_names))
        Sheets.Item(cell2mat(sheet)).Delete
    end
end
Workbook.Save;
Workbook.Close;
invoke(Excel, 'Quit');
delete(Excel);

