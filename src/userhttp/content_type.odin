package userhttp

// https://www.iana.org/assignments/media-types/media-types.xhtml

import "core:strings"

Content_Type_Binary :: "application/octet-stream"
Content_Type_Params :: "application/x-www-form-urlencoded; charset=UTF-8"
Content_Type_JSON   :: "application/json" // JSON is in UTF-8 by the standard. RFC 8259: No "charset" parameter is defined for this registration.
Content_Type_XML    :: "application/xml; charset=UTF-8"
Content_Type_Text   :: "text/plain; charset=UTF-8"

@private
guess_content_type_is_textual :: proc (content_type: string) -> bool {
    if content_type == "" do return false

    ct, err := strings.to_lower(content_type, context.temp_allocator)
    if err != nil do return false

    return\
        strings.has_prefix  (ct, "text/") ||
        strings.has_prefix  (ct, "application/json") ||
        strings.has_prefix  (ct, "application/xml") ||
        strings.contains    (ct, "charset=") ||
        strings.contains    (ct, "+json") ||
        strings.contains    (ct, "+xml") ||
        strings.contains    (ct, "javascript") ||
        strings.contains    (ct, "ecmascript")
}
