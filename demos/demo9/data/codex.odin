package data

import "core:encoding/json"
import "core:fmt"

Codex_Section :: struct {
    id      : string,
    title   : string,
    topics  : [] Codex_Topic,
}

Codex_Topic :: struct {
    id          : string,
    title       : string,
    articles    : [] Codex_Article,
}

Codex_Article :: struct {
    locked  : string,
    title   : string,
    desc    : Text,
}

/* @private */ codex: [] Codex_Section

@private
create_codex :: proc () {
    assert(codex == nil)

    err := json.unmarshal_any(#load("codex.json"), &codex)
    fmt.ensuref(err == nil, "Failed to load codex.json: %v", err)
    // fmt.printfln("%#v", codex)
}

@private
destroy_codex :: proc () {
    for s in codex {
        delete(s.id)
        delete(s.title)
        for t in s.topics {
            delete(t.id)
            delete(t.title)
            for a in t.articles {
                delete(a.locked)
                delete(a.title)
                delete_text(a.desc)
            }
            delete(t.articles)
        }
        delete(s.topics)
    }
    delete(codex)
    codex = nil
}

get_codex_section_stats :: proc (section: Codex_Section) -> (finished_topics, total_topics: int) {
    total_topics = len(section.topics)
    for t in section.topics {
        unlocked_articles, total_articles := get_codex_topic_stats(t)
        if unlocked_articles == total_articles {
            finished_topics += 1
        }
    }
    return
}

get_codex_topic_stats :: proc (topic: Codex_Topic) -> (unlocked_articles, total_articles: int) {
    total_articles = len(topic.articles)
    for a in topic.articles do if a.locked == "" do unlocked_articles += 1
    return
}

get_codex_topic :: proc (section_id, topic_id: string) -> Codex_Topic {
    for s in codex {
        if s.id == section_id {
            for t in s.topics {
                if t.id == topic_id {
                    return t
                }
            }
        }
    }
    fmt.panicf("Failed to locate topic \"%s\" in section \"%s\"", topic_id, section_id)
}
