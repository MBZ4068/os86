a=25
y=0
for i in range(a):
    x=i*320
    if y==5:
        print(str(x)+",")
        y=0
    else:
        print(str(x)+",",end="")
    y=y+1