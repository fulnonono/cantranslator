#ifndef _BITFIELD_H_
#define _BITFIELD_H_

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <stdbool.h>

/* Public: Reads a subset of bits from a byte array.
 *
 * data - the bytes in question.
 * startPos - the starting index of the bit field (beginning from 0).
 * numBits - the width of the bit field to extract.
 * bigEndian - if the data passed in is little endian, set this to false and it
 *      will be flipped before grabbing the bit field.
 *
 * Bit fields are positioned according to big-endian bit layout, but inside the
 * bit field, values are represented as little-endian. Therefore, to get the bit
 * field, we swap the overall byte order if bigEndian == false and
 * use the value we find in the field (assuming the embedded platform is little
 * endian).
 *
 * For example, the bit layout of the value "42" (i.e. 00101010 set at position
 * 14 with length 6 is:
 *
 *     000000000000001010100000000000000000000000000000000000000000000
 *
 * and the same value and position but with length 8 is:
 *
 *     000000000000000010101000000000000000000000000000000000000000000
 *
 * If the architecture where is code is running is little-endian, the input data
 * will be swapped before grabbing the bit field.
 *
 * Examples
 *
 *  uint64_t value = getBitField(data, 2, 4);
 *
 * Returns the value of the requested bit field.
 */
uint64_t getBitField(uint64_t data, int startPos, int numBits, bool bigEndian);

/* Public: Set the bit field in the given data array to the new value.
 *
 * data - a byte array with size at least startPos + numBits.
 * value - the value to set in the bit field.
 * startPos - the starting index of the bit field (beginning from 0).
 */
void setBitField(uint64_t* data, uint64_t value, int startPos, int numBits);

/* Public: Retreive the nth byte out of 8 bytes in a uint64_t.
 *
 * source - the source data to retreive the byte from.
 * byteNum - the index of the byte, starting at 0 and assuming big-endian order.
 *
 * Returns the requested byte from the source bytes.
 */
uint8_t nthByte(uint64_t source, int byteNum);

#ifdef __cplusplus
}
#endif

#endif // _BITFIELD_H_
