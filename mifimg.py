from math import sqrt

def inGrass(i):
	return ((399*640 < i) and (i < 640*400) and (i%2 == 0)) or (i >= 0 + 640*400)

def inCloud(i):
	row = i/640
	col = i%640
	if 20 < row and row < 100 and 400 < col and col < 500:
		return True
	elif 50 < row and row < 100 and 350 < col and col < 400:
		return True
	elif 80 < row and row < 100 and 250 < col and col < 280:
		return True
	else: 
		return False

def inSunLeft(i):
	sunrow = 100
	suncol = 100
	r = 80
	row = i/640
	col = i%640
	if sqrt((sunrow - row)**2 + (suncol - col)**2) < 80 and col < suncol:
		return True
	else:
		return False

def inSunRight(i):
	sunrow = 100
	suncol = 100
	r = 80
	row = i/640
	col = i%640
	if sqrt((sunrow - row)**2 + (suncol - col)**2) < 80 and col >= suncol:
		return True
	else:
		return False

def makeBackground():
	background = []
	limit = 307200
	for i in range(limit):
		if inGrass(i):
			background.append('1A')
		elif inCloud(i):
			background.append('1C')
		elif inSunLeft(i):
			background.append('1D')
		elif inSunRight(i):
			background.append('1E')
		else:
			background.append('1B')
	return background



lines = ['WIDTH = 8;\n', 'DEPTH = 307200;\n\n', 'ADDRESS_RADIX = DEC;\n', 'DATA_RADIX = HEX;\n\n', 'CONTENT BEGIN\n\n']

limit = 307199

background = makeBackground()

for i in range(limit):
	hex_val = background[i]
	lines.append(str(i) + ' : ' + hex_val + ';\n')

lines.append('END;\n')

with open('img_bars.mif', 'wb') as f:
	for line in lines:
		f.write(line)
	f.close()