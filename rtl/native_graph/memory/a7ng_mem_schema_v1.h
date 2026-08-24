/* a7ng_mem_schema_v1.h — C/host twin of rtl/native_graph/memory/a7ng_mem_schema_v1.svh
 * Law: a7ng-mem-schema-v1. Little-endian. Must match Python serdes golden vectors.
 */
#ifndef A7NG_MEM_SCHEMA_V1_H
#define A7NG_MEM_SCHEMA_V1_H

#include <stdint.h>

#define A7NG_MEM_SCHEMA_VERSION 1u

#define A7NG_NODE_REC_BYTES    16u
#define A7NG_EDGE_REC_BYTES    32u
#define A7NG_EPISODE_REC_BYTES 32u

/* NodeRecordV1 offsets */
#define A7NG_NODE_OFF_NODE_ID    0u
#define A7NG_NODE_OFF_NODE_TYPE  4u
#define A7NG_NODE_OFF_TOPIC_ID   6u
#define A7NG_NODE_OFF_CUE        8u
#define A7NG_NODE_OFF_CONFIDENCE 12u
#define A7NG_NODE_OFF_DEGREE_SAT 14u
#define A7NG_NODE_OFF_VERSION    15u

/* EdgeRecordV1 offsets */
#define A7NG_EDGE_OFF_SRC           0u
#define A7NG_EDGE_OFF_DST           4u
#define A7NG_EDGE_OFF_RELATION      8u
#define A7NG_EDGE_OFF_PAD0          10u
#define A7NG_EDGE_OFF_LEARNED_W     12u
#define A7NG_EDGE_OFF_TEACHER_PRIOR 14u
#define A7NG_EDGE_OFF_POS_COUNT     16u
#define A7NG_EDGE_OFF_NEG_COUNT     18u
#define A7NG_EDGE_OFF_LAST_EPOCH    20u
#define A7NG_EDGE_OFF_VERSION       24u
#define A7NG_EDGE_OFF_FLAGS         26u
#define A7NG_EDGE_OFF_CHECKSUM      28u

/* EpisodeRecordV1 offsets */
#define A7NG_EP_OFF_EPISODE_ID 0u
#define A7NG_EP_OFF_SUBJECT    4u
#define A7NG_EP_OFF_RELATION   8u
#define A7NG_EP_OFF_OBJECT     12u
#define A7NG_EP_OFF_CONTEXT    16u
#define A7NG_EP_OFF_SOURCE_REF 20u
#define A7NG_EP_OFF_ANSWER_REF 24u
#define A7NG_EP_OFF_CONFIDENCE 28u
#define A7NG_EP_OFF_VERSION    30u
#define A7NG_EP_OFF_FLAGS      31u

#pragma pack(push, 1)
typedef struct {
  uint32_t node_id;
  uint16_t node_type;
  uint16_t topic_id;
  uint32_t cue;
  uint16_t confidence;
  uint8_t  degree_sat;
  uint8_t  version;
} A7ngNodeRecordV1;

typedef struct {
  uint32_t src_node;
  uint32_t dst_node;
  uint16_t relation_type;
  uint16_t pad0;
  int16_t  learned_weight;
  int16_t  teacher_prior;
  uint16_t positive_count;
  uint16_t negative_count;
  uint32_t last_update_epoch;
  uint16_t version;
  uint16_t flags;
  uint32_t checksum; /* 0 = unused; else CRC32 of bytes [0..27] */
} A7ngEdgeRecordV1;

typedef struct {
  uint32_t episode_id;
  uint32_t subject;
  uint32_t relation;
  uint32_t object;
  uint32_t context;
  uint32_t source_ref;
  uint32_t answer_payload_ref;
  uint16_t confidence;
  uint8_t  version;
  uint8_t  flags;
} A7ngEpisodeRecordV1;
#pragma pack(pop)

#if defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 201112L)
_Static_assert(sizeof(A7ngNodeRecordV1) == A7NG_NODE_REC_BYTES, "NodeRecordV1 size");
_Static_assert(sizeof(A7ngEdgeRecordV1) == A7NG_EDGE_REC_BYTES, "EdgeRecordV1 size");
_Static_assert(sizeof(A7ngEpisodeRecordV1) == A7NG_EPISODE_REC_BYTES, "EpisodeRecordV1 size");
#endif

static inline uint32_t a7ng_node_byte_off(uint32_t node_id) {
  return node_id * A7NG_NODE_REC_BYTES;
}
static inline uint32_t a7ng_edge_byte_off(uint32_t edge_id) {
  return edge_id * A7NG_EDGE_REC_BYTES;
}
static inline uint32_t a7ng_episode_byte_off(uint32_t episode_id) {
  return episode_id * A7NG_EPISODE_REC_BYTES;
}

#endif /* A7NG_MEM_SCHEMA_V1_H */
