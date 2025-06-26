/* This is a public domain general purpose hash table package written by Peter Moore @ UCB. */

/* @(#) st.h 5.1 89/12/14 */

#ifndef ST_INCLUDED

#define ST_INCLUDED

typedef struct st_table st_table;

struct st_hash_type {
    int (*compare)();
    int (*hash)();
};

struct st_table {
    struct st_hash_type *type;
    int num_bins;
    int num_entries;
    struct st_table_entry **bins;
};

#define st_is_member(table,key) st_lookup(table,key,(char **)0)

enum st_retval {ST_CONTINUE, ST_STOP, ST_DELETE};

st_table * st_init_table(struct st_hash_type * type);
st_table * st_init_table_with_size(struct st_hash_type * type, int  size);
st_table * st_init_numtable();
st_table * st_init_numtable_with_size(int  size);
st_table * st_init_strtable();
st_table * st_init_strtable_with_size(int  size);
int  st_delete(register st_table * table, register char ** key, char ** value);
int  st_delete_safe(register st_table * table, register char ** key, char ** value, char * never);
int  st_insert(register st_table * table, register char * key, char * value);
int  st_lookup(st_table * table, register char * key, char ** value);
void  st_foreach(st_table * table, enum st_retval  (*func)(char*, char*, char*), char * arg);
void  st_add_direct(st_table * table, char * key, char * value);
void  st_free_table(st_table * table);
void  st_cleanup_safe(st_table * table, char * never);
st_table * st_copy(st_table * old_table);
#define ST_NUMCMP	((int (*)()) 0)
#define ST_NUMHASH	((int (*)()) -2)

#define st_numcmp	ST_NUMCMP
#define st_numhash	ST_NUMHASH

int st_strhash();

#endif /* ST_INCLUDED */
