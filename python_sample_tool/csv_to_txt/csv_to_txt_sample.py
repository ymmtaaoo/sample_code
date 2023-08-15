datanum = 5

inputList = []
i = 0
for x in open('input.csv'):
	#1行目を飛ばす
	if (i > 0):
		inputList.append([x.split(',')[0], x.split(',')[1], x.split(',')[2], x.split(',')[3], x.split(',')[4]])
		inputList.append([x.split(',')[0], x.split(',')[1], x.split(',')[2], x.split(',')[3], x.split(',')[4]])
		inputList.append([x.split(',')[0], x.split(',')[1], x.split(',')[2], x.split(',')[3], x.split(',')[4]])
	#print(x.split(',')[0])
	#print(x.split(',')[1])
	#print(x.split(',')[2])
	#print(x.split(',')[3])
	#print(x.split(',')[4])
	i = i+1
	if (i > datanum):
		break

for x in inputList:
	print(x)

outFile = open('out.txt', 'w')
i = 0
for x in open('template.csv', encoding='ms932', newline='\n'):

	if (i > 3*datanum):
		break
	#1行目を飛ばす
	if (i >= 1):
		print(inputList[i-1][0])
		outFile.write(x.split(',')[0])
		outFile.write(inputList[i-1][0])
		outFile.write(x.split(',')[1])
		outFile.write(inputList[i-1][1].ljust(5,'　'))
		outFile.write(x.split(',')[2])
		outFile.write(inputList[i-1][2].ljust(5,'　'))
		outFile.write(x.split(',')[3])
		outFile.write(inputList[i-1][3].ljust(10,' '))
		outFile.write(x.split(',')[4])
		outFile.write(inputList[i-1][4].ljust(10,' '))
		outFile.write(x.split(',')[5])
		outFile.write(x.split(',')[6])
		outFile.write(x.split(',')[7])

	i = i+1

