import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

import org.apache.poi.EncryptedDocumentException;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;

public class Main {
	public static void main (String[] args) throws EncryptedDocumentException, IOException {
		//Excelファイルにアクセス
		Workbook excel = WorkbookFactory.create(new File("input.xlsx"));
		
		try {
			File file = new File("output.txt");
			BufferedWriter bw = new BufferedWriter(new FileWriter(file));
			int maxSheetNum = excel.getNumberOfSheets();
			for (int j = 0; j < maxSheetNum-1; j++) {
				print(excel, bw, j)
			}
			bw.close();
		}
		
	}
	
	private static void print(Workbook excel, BufferedWriter bw, int num) throws IOException {
		String sheetName = excel.getSheetName(num);
		Sheet sheet = excel.getSheet(sheetName);
		bw.write(sheetName);
		bw.newLine();
		bw.write(sheet.getRow(1).getCell(1).getStringCellValue());
		bw.newLine();
		bw.newLine();
	}
	
}
