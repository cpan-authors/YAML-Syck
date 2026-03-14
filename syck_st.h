/* This is a public domain general purpose hash table package written by Peter Moore @ UCB. */

/* @(#) st.h 5.1 89/12/14 */

#ifndef ST_INCLUDED

#define ST_INCLUDED

typedef struct st_table st_table;

struct st_hash_type {
    int (*compare)(char *, char *);
    int (*hash)(char *);
};

struct st_table {
    struct st_hash_type *type;
    int num_bins;
    int num_entries;
    struct st_table_entry **bins;
};

#define st_is_member(table,key) st_lookup(table,key,(char **)0)

enum st_retval {ST_CONTINUE, ST_STOP, ST_DELETE};

st_table *st_init_table(struct st_hash_type *);
st_table *st_init_table_with_size(struct st_hash_type *, int);
st_table *st_init_numtable(void);
st_table *st_init_numtable_with_size(int);
st_table *st_init_strtable(void);
st_table *st_init_strtable_with_size(int);
int st_delete(st_table *, char **, char **);
int st_delete_safe(st_table *, char **, char **, char *);
int st_insert(st_table *, char *, char *);
int st_lookup(st_table *, char *, char **);
void st_foreach(st_table *, enum st_retval (*)(), char *);
void st_add_direct(st_table *, char *, char *);
void st_free_table(st_table *);
void st_cleanup_safe(st_table *, char *);
st_table *st_copy(st_table *);

#define ST_NUMCMP	((int (*)(char *, char *)) 0)
#define ST_NUMHASH	((int (*)(char *)) -2)

#define st_numcmp	ST_NUMCMP
#define st_numhash	ST_NUMHASH

int st_strhash(char *);

#endif /* ST_INCLUDED */
