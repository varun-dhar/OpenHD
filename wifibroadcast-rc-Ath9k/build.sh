g++ -I../wifibroadcast-base rctx.cpp -o rctx `sdl-config --libs` `sdl-config --cflags` -lrt -lwiringPi -lpcap -lboost_system -lboost_regex -lboost_filesystem -lboost_thread -lpthread
g++ -I../wifibroadcast-base rcswitches.cpp -o rcswitches `sdl-config --libs` `sdl-config --cflags` -lrt 