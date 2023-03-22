#include <stdint.h>

//#include <stdio.h>
//#include <inttypes.h>
//void tiny_ubsan_event_occurred(void *addressOfEvent, const char *message, const char *file, uint32_t line, uint32_t column)
//{
//	printf("TINY_UBSAN: %s at %p in %s:%"PRIu32":%"PRIu32"\n",
//			message,
//			addressOfEvent,
//			file,
//			line,
//			column);
//}

void tiny_ubsan_event_occurred(void *addressOfEvent, const char *message, const char *file, uint32_t line, uint32_t column);

struct tu_source_location
{
    const char *file;
    uint32_t line;
    uint32_t column;
};

struct tu_type_descriptor
{
    uint16_t kind;
    uint16_t info;
    char name[];
};

struct tu_overflow_data
{
    struct tu_source_location location;
    struct tu_type_descriptor *type;
};

struct tu_shift_out_of_bounds_data
{
    struct tu_source_location location;
    struct tu_type_descriptor *left_type;
    struct tu_type_descriptor *right_type;
};

struct tu_invalid_value_data
{
    struct tu_source_location location;
    struct tu_type_descriptor *type;
};

struct tu_array_out_of_bounds_data
{
    struct tu_source_location location;
    struct tu_type_descriptor *array_type;
    struct tu_type_descriptor *index_type;
};

struct tu_type_mismatch_v1_data
{
    struct tu_source_location location;
    struct tu_type_descriptor *type;
    unsigned char log_alignment;
    unsigned char type_check_kind;
};

struct tu_negative_vla_data
{
    struct tu_source_location location;
    struct tu_type_descriptor *type;
};

struct tu_nonnull_return_data
{
    struct tu_source_location location;
};

struct tu_nonnull_arg_data
{
    struct tu_source_location location;
};

struct tu_unreachable_data
{
    struct tu_source_location location;
};

struct tu_invalid_builtin_data
{
    struct tu_source_location location;
    unsigned char kind;
};

#define tu_process_event(msg, loc) tiny_ubsan_event_occurred(__builtin_return_address(0), msg, (loc).file, (loc).line, (loc).column)

#ifdef __cplusplus
extern "C"
{
#endif
    void __ubsan_handle_add_overflow(struct tu_overflow_data *data)
    {
        tu_process_event("addition overflow", data->location);
    }

    void __ubsan_handle_sub_overflow(struct tu_overflow_data *data)
    {
        tu_process_event("subtraction overflow", data->location);
    }

    void __ubsan_handle_mul_overflow(struct tu_overflow_data *data)
    {
        tu_process_event("multiplication overflow", data->location);
    }

    void __ubsan_handle_divrem_overflow(struct tu_overflow_data *data)
    {
        tu_process_event("division overflow", data->location);
    }

    void __ubsan_handle_negate_overflow(struct tu_overflow_data *data)
    {
        tu_process_event("negation overflow", data->location);
    }

    void __ubsan_handle_pointer_overflow(struct tu_overflow_data *data)
    {
        tu_process_event("pointer overflow", data->location);
    }

    void __ubsan_handle_shift_out_of_bounds(struct tu_shift_out_of_bounds_data *data)
    {
        tu_process_event("shift out of bounds", data->location);
    }

    void __ubsan_handle_load_invalid_value(struct tu_invalid_value_data *data)
    {
        tu_process_event("invalid load value", data->location);
    }

    void __ubsan_handle_out_of_bounds(struct tu_array_out_of_bounds_data *data)
    {
        tu_process_event("array out of bounds", data->location);
    }

    void __ubsan_handle_type_mismatch_v1(struct tu_type_mismatch_v1_data *data, uintptr_t ptr)
    {
        if (!ptr)
        {
            tu_process_event("use of NULL pointer", data->location);
        }
        else if (ptr & ((1 << data->log_alignment) - 1))
        {
            tu_process_event("use of misaligned pointer", data->location);
        }
        else
        {
            tu_process_event("no space for object", data->location);
        }
    }

    void __ubsan_handle_vla_bound_not_positive(struct tu_negative_vla_data *data)
    {
        tu_process_event("variable-length argument is negative", data->location);
    }

    void __ubsan_handle_nonnull_return(struct tu_nonnull_return_data *data)
    {
        tu_process_event("non-null return is null", data->location);
    }

    void __ubsan_handle_nonnull_arg(struct tu_nonnull_arg_data *data)
    {
        tu_process_event("non-null argument is null", data->location);
    }

    void __ubsan_handle_builtin_unreachable(struct tu_unreachable_data *data)
    {

        tu_process_event("unreachable code reached", data->location);
    }

    void __ubsan_handle_invalid_builtin(struct tu_invalid_builtin_data *data)
    {

        tu_process_event("invalid builtin", data->location);
    }

#ifdef __cplusplus
}
#endif
