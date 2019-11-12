// <io> -*- C++ -*-
/*
	io - A tiny header presenting common IO objects
	Copyright (C) 2019 Mivik

	This file is part of the DimenX library. This library is free
	software: you can redistribute it and/or modify it under the terms
	of the GNU General Public License as published by the Free Software
	Foundation, either version 3 of the License, or (at your option)
	any later version.

	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this library.  If not, see <https://www.gnu.org/licenses/>.
*/


#ifndef __DIMENX_IO_H_
#define __DIMENX_IO_H_

#include <string.h>
#include <stdio.h>
#include <unistd.h>
#include <dirent.h>
#include <assert.h>

#include <string>
#include <vector>

#include <sys/stat.h>
#include <linux/limits.h>

namespace dimenx {

#if defined(WIN32) || defined(_WIN32) 
#define PATH_SEPARATOR '\\'
#else
#define PATH_SEPARATOR '/'
#endif

struct FileStat {
private:
	struct stat info;
public:
	FileStat() {}
	FileStat(const char *path) {load(path);}
	inline bool load(const char *path) { return lstat(path,&info)==0; }
	inline bool isFile() const { return S_ISREG(info.st_mode); }
	inline bool isDirectory() const { return S_ISDIR(info.st_mode); }
	inline bool isCharacterDevice() const { return S_ISCHR(info.st_mode); }
	inline bool isBlockDevice() const { return S_ISBLK(info.st_mode); }
	inline bool isLink() const { return S_ISLNK(info.st_mode); }
	inline bool isSocketFile() const { return S_ISSOCK(info.st_mode); }
	inline bool isFIFO() const { return S_ISFIFO(info.st_mode); }
	inline mode_t getMode() const { return info.st_mode; }
	inline time_t getLastModifyTime() const { return info.st_mtime; }
	inline time_t getLastAccessTime() const { return info.st_atime; }
	inline time_t getLastStatusChangeTime() const { return info.st_ctime; }
	inline size_t getSize() const { return info.st_size; }
	inline uid_t getOwnerUID() const { return info.st_uid; }
	inline gid_t getOwnerGID() const { return info.st_gid; }
	inline nlink_t getHardLinkCount() const { return info.st_nlink; }
	inline dev_t getDeviceID() const { return info.st_dev; }
	inline dev_t getInodeID() const { return info.st_rdev; }
	inline blksize_t getBlockSize() const { return info.st_blksize; }
	inline blkcnt_t getBlockCount() const { return info.st_blocks; }
};

struct File;
struct FileFilter {
	virtual bool operator()(const char *parent, const char *name) const {
		int len=strlen(name);
		if (len==1&&name[0]=='.') return false;
		if (len==2&&name[0]=='.'&&name[1]=='.') return false;
		return true;
	}
};
struct FileStream {
private:
	FILE *file;
public:
	FileStream() {}
	FileStream(FILE *file):file(file) {}
	FileStream(const char *path, const char *mode) { file=fopen(path,mode); }
	inline void reopen(const char *path, const char *mode) { freopen(path,mode,file); }
	inline void seek(const long &offset, const int &origin) { fseek(file,offset,origin); }
	inline void read(void *ptr, const size_t &itemSize, const size_t &itemCnt) { fread(ptr,itemSize,itemCnt,file); }
	inline void write(const void *ptr, const size_t &itemSize, const size_t &itemCnt) { fwrite(ptr,itemSize,itemCnt,file); }
	inline long tell() { return ftell(file); }
	inline void close() { fclose(file); }
	inline void putchar(const char &c) { fputc(c,file); }
	inline char getchar() { return fgetc(file); }
	inline int scanf(const char *format, ...) {
		va_list args;
		va_start(args,format);
		return vfscanf(file,format,args);
	}
	inline void printf(const char *format, ...) {
		va_list args;
		va_start(args,format);
		return vfprintf(file,format,args);
	}
	inline bool eof() { return feof(file); }
	inline int error() { return ferror(file); }
	inline void clearError() { ::clearerr(file); }
	inline void rewind() { ::rewind(file); }
	inline FILE *getFile() { return file; }
};

struct File {
private:
	std::string path;
	mutable FileStat *info;
	inline bool loadInfo() const {
		if (!exists()) return 0;
		if (!info) {
			info=new FileStat();
			if (!info->load(path.c_str())) return 0;
		}
		return 1;
	}
	inline void updatePath() {
		if (path.length()>1&&(*(path.end()-1))==PATH_SEPARATOR) this->path.erase(this->path.end()-1);
		if (info) info=0;
	}
public:
	File() {}
	File(const std::string &path) {setPath(path);}
	File(const char *path) {setCPath(path);}
	File(const File &parent, const char *name) {
		assert(parent.isDirectory());
		path=parent.path;
		if ((*(parent.path.end()-1))!=PATH_SEPARATOR) path+=PATH_SEPARATOR;
		path+=name;
		updatePath();
	}
	// ~File() {if(info)delete info;}
#define E if(!loadInfo())return 0
	inline bool exists() const { return access(path.c_str(),F_OK)==0; }
	inline bool canWrite() const { return access(path.c_str(),W_OK)==0; }
	inline bool canRead() const { return access(path.c_str(),R_OK)==0; }
	inline bool canExecute() const { return access(path.c_str(),X_OK)==0; }
	inline bool isFile() const { E;return info->isFile(); }
	inline bool isDirectory() const { E;return info->isDirectory(); }
	inline bool isCharacterDevice() const { E;return info->isCharacterDevice(); }
	inline bool isBlockDevice() const { E;return info->isBlockDevice(); }
	inline bool isLink() const { E;return info->isLink(); }
	inline bool isSocketFile() const { E;return info->isSocketFile(); }
	inline bool isFIFO() const { E;return info->isFIFO(); }
	inline mode_t getMode() const { E;return info->getMode(); }
	inline time_t getLastModifyTime() const { E;return info->getLastModifyTime(); }
	inline time_t getLastAccessTime() const { E;return info->getLastAccessTime(); }
	inline time_t getLastStatusChangeTime() const { E;return info->getLastStatusChangeTime(); }
	inline size_t getSize() const { E;return info->getSize(); }
	inline uid_t getOwnerUID() const { E;return info->getOwnerUID(); }
	inline gid_t getOwnerGID() const { E;return info->getOwnerGID(); }
	inline nlink_t getHardLinkCount() const { E;return info->getHardLinkCount(); }
	inline dev_t getDeviceID() const { E;return info->getDeviceID(); }
	inline dev_t getInodeID() const { E;return info->getInodeID(); }
	inline blksize_t getBlockSize() const { E;return info->getBlockSize(); }
	inline blkcnt_t getBlockCount() const { E;return info->getBlockCount(); }
	inline FileStat getFileStat() const { E;return *info; }
	inline std::string getPath() const { return path; }
	inline const char *getCPath() const { return path.c_str(); }
	inline void setPath(const std::string &path) {
		this->path=path;
		updatePath();
	}
	inline void setCPath(const char *path) {
		this->path=path;
		updatePath();
	}
	inline File getLinkedFile() const {
		File ret(getLinkedCPath());
		return ret;
	}
	inline std::string getLinkedPath() const {
		if (!isLink()) return "";
		std::string ret=getLinkedCPath();
		return ret;
	}
	inline const char *getLinkedCPath() const {
		char ret[PATH_MAX];
		if (!isLink()) {
			ret[0]='\0';
			return ret;
		}
		readlink(path.c_str(),ret,PATH_MAX);
		return ret;
	}
	inline File getAbsoluteFile() const {
		File ret(getAbsoluteCPath());
		return ret;
	}
	inline std::string getAbsolutePath() const {
		std::string ret=getAbsoluteCPath();
		return ret;
	}
	inline const char *getAbsoluteCPath() const {
		char ret[PATH_MAX];
		realpath(path.c_str(),ret);
		return ret;
	}
	std::vector<File> listRawFiles() const {
		std::vector<File> ret;
		if (!isDirectory()) return ret;
		DIR *dir=opendir(path.c_str());
		if (!dir) return ret;
		dirent *ent;
		while ((ent=readdir(dir))) ret.push_back(*(new File(*this,ent->d_name)));
		closedir(dir);
		return ret;
	}
	std::vector<File> listFiles(const FileFilter &filter=FileFilter()) const {
		std::vector<File> ret;
		if (!isDirectory()) return ret;
		DIR *dir=opendir(path.c_str());
		if (!dir) return ret;
		dirent *ent;
		const char *we=path.c_str();
		while ((ent=readdir(dir)))
			if (filter(we,ent->d_name)) ret.push_back(*(new File(*this,ent->d_name)));
		closedir(dir);
		return ret;
	}
	std::string getName() const {
		int ind=path.length()-1;
		while (ind>=0&&path[ind]!=PATH_SEPARATOR) --ind;
		return path.substr(ind+1);
	}
	inline bool rename(const File &f) const { return ::rename(path.c_str(),f.path.c_str())==0; }
	inline FileStream open(const char *mode) const { return FileStream(path.c_str(),mode); }
	inline bool remove() const {
		if (isFile()) return unlink(path.c_str())==0;
		else if (isDirectory()) return rmdir(path.c_str())==0;
	}
#undef E
};

};

#endif