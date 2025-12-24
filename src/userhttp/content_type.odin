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
    return\
        strings.contains(content_type, "charset=") ||
        strings.has_prefix(content_type, "text/") ||
        strings.has_prefix(content_type, "application/json")
}
