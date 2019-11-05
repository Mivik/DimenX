#include <iostream>
#include <dimenx/crypto/md5>

using namespace std;
using namespace dimenx::crypto;

MD5 obj;
char output[16];
int main() {
	obj.reset();
	obj.update("qq");
	cout<<Bytes2Hex(obj.digest(),16,output)<<endl;
	return 0;
}