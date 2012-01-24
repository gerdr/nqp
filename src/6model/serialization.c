/* This implements bounded serialization, or at least drives the overall
 * process. Representations know how to serialize and deserialize themselves.
 * So mostly, this does the rest of the work. */

#define PARROT_IN_EXTENSION
#include "parrot/parrot.h"
#include "parrot/extend.h"
#include "sixmodelobject.h"
#include "serialization_context.h"
#include "pmc_serializationcontext.h"

/* Version of the serialization format that we are currently at. */
#define CURRENT_VERSION 1

/* Various sizes (in bytes). */
#define HEADER_SIZE                 4 * 9
#define DEP_TABLE_ENTRY_SIZE        8
#define STABLE_TABLE_ENTRY_SIZE     8
#define OBJECTS_TABLE_ENTRY_SIZE    12

/* Some guesses. */
#define DEFAULT_STABLE_DATA_SIZE    4096
#define OBJECT_SIZE_GUESS           8

/* Writes an int32 into a buffer. */
static void write_int32(char *buffer, size_t offset, Parrot_Int4 value) {
    /* XXX: Big Endian Handling! */
    memcpy(buffer + offset, &value, 4);
}

/* Writes an int16 into a buffer. */
static void write_int16(char *buffer, size_t offset, Parrot_Int2 value) {
    /* XXX: Big Endian Handling! */
    memcpy(buffer + offset, &value, 2);
}

/* Concatenates the various output segments into a single binary string. */
static STRING * concatenate_outputs(PARROT_INTERP, SerializationWriter *writer) {
    char        *output      = NULL;
    Parrot_Int4  output_size = 0;
    Parrot_Int4  offset      = 0;
    
    /* Calculate total size. */
    output_size += HEADER_SIZE;
    output_size += writer->root.num_dependencies * DEP_TABLE_ENTRY_SIZE;
    output_size += writer->root.num_stables * STABLE_TABLE_ENTRY_SIZE;
    output_size += writer->stables_data_offset;
    output_size += writer->root.num_objects * OBJECTS_TABLE_ENTRY_SIZE;
    output_size += writer->objects_data_offset;
    
    /* Allocate a buffer that size. */
    output = mem_sys_allocate(output_size);
    
    /* Write version into header. */
    write_int32(output, 0, CURRENT_VERSION);
    offset += HEADER_SIZE;
    
    /* Put dependencies table in place and set location/rows in header. */
    write_int32(output, 4, offset);
    write_int32(output, 8, writer->root.num_dependencies);
    memcpy(output + offset, writer->root.dependencies_table, 
        writer->root.num_dependencies * DEP_TABLE_ENTRY_SIZE);
    offset += writer->root.num_dependencies * DEP_TABLE_ENTRY_SIZE;
    
    /* Put STables table in place, and set location/rows in header. */
    write_int32(output, 12, offset);
    write_int32(output, 16, writer->root.num_stables);
    memcpy(output + offset, writer->root.stables_table, 
        writer->root.num_stables * STABLE_TABLE_ENTRY_SIZE);
    offset += writer->root.num_stables * STABLE_TABLE_ENTRY_SIZE;
    
    /* Put STables data in place. */
    write_int32(output, 20, offset);
    memcpy(output + offset, writer->root.stables_data, 
        writer->stables_data_offset);
    offset += writer->stables_data_offset;
    
    /* Put objects table in place, and set location/rows in header. */
    write_int32(output, 24, offset);
    write_int32(output, 28, writer->root.num_objects);
    memcpy(output + offset, writer->root.objects_table, 
        writer->root.num_objects * OBJECTS_TABLE_ENTRY_SIZE);
    offset += writer->root.num_objects * OBJECTS_TABLE_ENTRY_SIZE;
    
    /* Put objects data in place. */
    write_int32(output, 32, offset);
    memcpy(output + offset, writer->root.objects_data, 
        writer->objects_data_offset);
    offset += writer->objects_data_offset;
    
    /* Sanity check. */
    if (offset != output_size)
        Parrot_ex_throw_from_c_args(interp, NULL, EXCEPTION_INVALID_OPERATION,
            "Serialization sanity check failed: offset != output_size");
    
    /* Make a Parrot binary string containing it (external flag means use
     * this buffer, not copy it to a new one). */
    return Parrot_str_new_init(interp, output, output_size,
        Parrot_binary_encoding_ptr, PObj_external_FLAG);
}

/* This handles the serialization of an STable, and calls off to serialize
 * its representation data also. */
static void serialize_stable(PARROT_INTERP, SerializationWriter *writer, PMC *st) {
    Parrot_ex_throw_from_c_args(interp, NULL, EXCEPTION_INVALID_OPERATION,
        "STable serialization not yet implemented");
}

/* This handles the serialization of an object, which largely involves a
 * delegation to its representation. */
static void serialize_object(PARROT_INTERP, SerializationWriter *writer, PMC *obj) {
    Parrot_ex_throw_from_c_args(interp, NULL, EXCEPTION_INVALID_OPERATION,
        "Object serialization not yet implemented");
}

/* This is the overall serialization loop. It keeps an index into the list of
 * STables and objects in the SC. As we discover new ones, they get added. We
 * finished when we've serialized everything. */
static void serialize(PARROT_INTERP, SerializationWriter *writer) {
    INTVAL work_todo = 1;
    while (work_todo) {
        /* Current work list sizes. */
        INTVAL stables_todo = VTABLE_elements(interp, writer->stables_list);
        INTVAL objects_todo = VTABLE_elements(interp, writer->objects_list);
        
        /* Reset todo flag - if we do some work we'll go round again as it
         * may have generated more. */
        work_todo = 0;
        
        /* Serialize any STables on the todo list. */
        while (writer->stables_list_pos < stables_todo) {
            serialize_stable(interp, writer, VTABLE_get_pmc_keyed_int(interp,
                writer->stables_list, writer->stables_list_pos));
            writer->stables_list_pos++;
            work_todo = 1;
        }
        
        /* Serialize any objects on the todo list. */
        while (writer->objects_list_pos < objects_todo) {
            serialize_object(interp, writer, VTABLE_get_pmc_keyed_int(interp,
                writer->objects_list, writer->objects_list_pos));
            writer->objects_list_pos++;
            work_todo = 1;
        }
    }
}

/* Takes a serialization context along with an empty string array. Taking the
 * serialization context's contents as the roots, recursively walks them until
 * everything is serialized or a reference to something already serialized in
 * another context. */
STRING * Serialization_serialize(PARROT_INTERP, PMC *sc, PMC *empty_string_heap) {
    PMC         *stables  = PMCNULL;
    PMC         *objects  = PMCNULL;
    STRING      *result   = STRINGNULL;
    Parrot_Int4  sc_elems = (Parrot_Int4)VTABLE_elements(interp, sc);
    
    /* Set up writer with some initial settings. */
    SerializationWriter *writer = mem_allocate_zeroed_typed(SerializationWriter);
    GETATTR_SerializationContext_root_stables(interp, sc, stables);
    GETATTR_SerializationContext_root_objects(interp, sc, objects);
    writer->root.version        = CURRENT_VERSION;
    writer->stables_list        = stables;
    writer->objects_list        = objects;
    writer->root.string_heap    = empty_string_heap;
    writer->root.dependent_scs  = Parrot_pmc_new(interp, enum_class_ResizablePMCArray);
    
    /* Allocate initial memory space for storing serialized tables and data. */
    writer->dependencies_table_alloc = DEP_TABLE_ENTRY_SIZE * 4;
    writer->root.dependencies_table  = mem_sys_allocate(writer->dependencies_table_alloc);
    writer->stables_table_alloc      = STABLE_TABLE_ENTRY_SIZE * (sc_elems || 1);
    writer->root.stables_table       = mem_sys_allocate(writer->stables_table_alloc);
    writer->objects_table_alloc      = OBJECTS_TABLE_ENTRY_SIZE * (sc_elems || 1);
    writer->root.objects_table       = mem_sys_allocate(writer->objects_table_alloc);
    writer->stables_data_alloc       = DEFAULT_STABLE_DATA_SIZE;
    writer->root.stables_data        = mem_sys_allocate(writer->stables_data_alloc);
    writer->objects_data_alloc       = OBJECT_SIZE_GUESS * (sc_elems || 1);
    writer->root.objects_data        = mem_sys_allocate(writer->objects_data_alloc);
    
    /* Populate write functions table. */
    

    /* Start serializing. */
    serialize(interp, writer);

    /* Build a single result string out of the serialized data. */
    result = concatenate_outputs(interp, writer);

    /* Clear up afterwards. */
    mem_sys_free(writer->root.dependencies_table);
    mem_sys_free(writer->root.stables_table);
    mem_sys_free(writer->root.stables_data);
    mem_sys_free(writer->root.objects_table);
    mem_sys_free(writer->root.objects_data);
    mem_sys_free(writer);
    
    return result;
}

/* Takes serialized data, an empty SerializationContext to deserialize it into
 * and a strings heap. Deserializes the data into the required objects and
 * STables. */
void Serialization_deserialize(PARROT_INTERP, PMC *sc, PMC *string_heap, STRING *data) {
}