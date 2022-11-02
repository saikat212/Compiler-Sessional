yaccFile=1705116.y
lexFile=1705116.l
inputFile=input.txt

DIR="$(cd "$(dirname "$0")" && pwd)"
cd $DIR
bison -d -y -v ./$yaccFile
g++ -w -c -o ./y.o ./y.tab.c
flex -o ./lex.yy.c ./$lexFile
g++ -fpermissive -w -c -o ./l.o ./lex.yy.c
g++ -o ./a.out ./y.o ./l.o -lfl
./a.out ./input.c











