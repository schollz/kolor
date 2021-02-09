
lib/cjson.so:
	rm -rf lua-cjson
	git clone https://github.com/mpx/lua-cjson.git
	cd lua-cjson && cc -c -O3 -Wall -pedantic -DNDEBUG  -I/usr/include/lua5.2 -fpic -pthread -DMULTIPLE_THREADS -o lua_cjson.o lua_cjson.c
	cd lua-cjson && cc -c -O3 -Wall -pedantic -DNDEBUG  -I/usr/include/lua5.2 -fpic -pthread -DMULTIPLE_THREADS -o strbuf.o strbuf.c
	cd lua-cjson && cc -c -O3 -Wall -pedantic -DNDEBUG  -I/usr/include/lua5.2 -fpic -pthread -DMULTIPLE_THREADS -o fpconv.o fpconv.c
	cd lua-cjson && cc  -shared -pthread -o cjson.so lua_cjson.o strbuf.o fpconv.o
	mv lua-cjson/cjson.so lib/
	rm -rf lua-cjson

