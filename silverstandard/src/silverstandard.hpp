#pragma once

#include <unordered_map>
#include <vector>
#include <fstream>
#include <functional>

#include <seqan/seq_io.h>
#include <seqan/blast.h>
#include <seqan/translation.h>



using namespace seqan;

template <BlastProgram p>
using OrigQryAlph = typename std::conditional<
                                           (p == BlastProgram::BLASTN) ||
                                           (p == BlastProgram::BLASTX) ||
                                           (p == BlastProgram::TBLASTX),
                                           Dna5,
                                           AminoAcid>::type;

template <BlastProgram p>
using OrigSubjAlph = typename std::conditional<
                                           (p == BlastProgram::BLASTN) ||
                                           (p == BlastProgram::TBLASTN) ||
                                           (p == BlastProgram::TBLASTX),
                                           Dna5,
                                           AminoAcid>::type;

template <BlastProgram p>
using TransAlph = typename std::conditional<(p == BlastProgram::BLASTN),
                                            Dna5,
                                            AminoAcid>::type;

// ----------------------------------------------------------------------------
// Tag Truncate_ (private tag to signify truncating of IDs while reading)
// ----------------------------------------------------------------------------

struct Truncate_;


static thread_local std::string _buffer;

namespace std
{
    // this hash just returns the memory address of the
    // dynamically allocated memory region of the string
    // therefore it changes, when the string changes
    // AND IT EXPECTS THE STRING TO BE INITIALIZED
    template<> struct hash<String<char, Alloc<Truncate_>> >
    {
        typedef String<char, Alloc<Truncate_>> argument_type;
        typedef std::size_t result_type;
        result_type operator()(argument_type const& s) const
        {
            assign(_buffer, s);
            return std::hash<std::string>()(_buffer);
        }
    };
}

// ----------------------------------------------------------------------------
// Function readRecord(Fasta); an overload that truncates Ids at first Whitespace
// ----------------------------------------------------------------------------

template <typename TSeqStringSet, typename TSpec, typename TSize>
inline void
readRecords(StringSet<String<char, Alloc<Truncate_>>> & meta,
            TSeqStringSet & seq,
            FormattedFile<Fastq, Input, TSpec> & file,
            TSize maxRecords)
{
    typedef typename SeqFileBuffer_<TSeqStringSet, TSpec>::Type TSeqBuffer;

    TSeqBuffer seqBuffer;
    IsWhitespace func;

    // reuse the memory of context(file).buffer for seqBuffer (which has a different type but same sizeof(Alphabet))
    swapPtr(seqBuffer.data_begin, context(file).buffer[1].data_begin);
    swapPtr(seqBuffer.data_end, context(file).buffer[1].data_end);
    seqBuffer.data_capacity = context(file).buffer[1].data_capacity;

    for (; !atEnd(file) && maxRecords > 0; --maxRecords)
    {
        readRecord(context(file).buffer[0], seqBuffer, file);
        for (size_t i = 0; i < length(context(file).buffer[0]); ++i)
        {
            if (func(context(file).buffer[0][i]))
            {
                resize(context(file).buffer[0], i);
                break;
            }
        }
        appendValue(meta, context(file).buffer[0]);
        appendValue(seq, seqBuffer);
    }

    swapPtr(seqBuffer.data_begin, context(file).buffer[1].data_begin);
    swapPtr(seqBuffer.data_end, context(file).buffer[1].data_end);
    context(file).buffer[1].data_capacity = seqBuffer.data_capacity;
    seqBuffer.data_capacity = 0;
}

// ----------------------------------------------------------------------------
// Generic Sequence loading
// ----------------------------------------------------------------------------

template <typename TSpec1,
          typename TSpec2,
          typename TFile>
inline int
myReadRecords(StringSet<String<char, TSpec1>> & ids,
              StringSet<String<Dna5, TSpec2>, Owner<ConcatDirect<>>> & seqs,
              TFile                                                  & file)
{
    StringSet<String<Iupac>, Owner<ConcatDirect<>>> tmpSeqs; // all IUPAC nucleic acid characters are valid input
    try
    {
        readRecords(ids, tmpSeqs, file);
    }
    catch(ParseError const & e)
    {
        std::cerr << "\nParseError thrown: " << e.what() << '\n'
                  << "Make sure that the file is standards compliant. If you get an unexpected character warning "
                  << "make sure you have set the right program parameter (-p), i.e. "
                  << "Lambda expected nucleic acid alphabet, maybe the file was protein?\n";
        return -1;
    }

    seqs = tmpSeqs; // convert IUPAC alphabet to Dna5

    return 0;
}

template <typename TSpec1,
          typename TSpec2,
          typename TFile>
inline int
myReadRecords(StringSet<String<char, TSpec1>>      & ids,
              StringSet<String<AminoAcid, TSpec2>, Owner<ConcatDirect<>>> & seqs,
              TFile                                                       & file)
{
    try
    {
        readRecords(ids, seqs, file);
    }
    catch(ParseError const & e)
    {
        std::cerr << "\nParseError thrown: " << e.what() << '\n'
                  << "Make sure that the file is standards compliant.\n";
        return -1;
    }

    if (length(seqs) > 0)
    {
        // warn if sequences look like DNA
        if (CharString(String<Dna5>(CharString(seqs[0]))) == CharString(seqs[0]))
            std::cout << "\nWarning: The first query sequence looks like nucleic acid, but amino acid is expected.\n"
                         "           Make sure you have set the right program parameter (-p).\n";
    }

    return 0;
}

template <typename TAlph, typename TSpec>
inline void
translateOrSwap(StringSet<String<TAlph>, TSpec> & out, StringSet<String<TAlph>, TSpec> & in)
{
    swap(out, in);
}

template <typename TSpec1, typename TSpec2>
inline void
translateOrSwap(StringSet<String<AminoAcid>, TSpec1> & out, StringSet<String<Dna5>, TSpec2> & in)
{
    translate(out, in, SIX_FRAME, Parallel());
}

inline void
hashIds(std::unordered_map<String<char, Alloc<Truncate_>>, size_t> & out,
        StringSet<String<char, Alloc<Truncate_>>> const & in)
{
    out.reserve(length(in));
    for (size_t i = 0; i < length(in); ++i)
        out[in[i]] = i;
}

inline void
readPairsAndAssign(std::vector<std::vector<size_t>> & out,
                   std::unordered_map<String<char, Alloc<Truncate_>>, size_t> const & qMap,
                   std::unordered_map<String<char, Alloc<Truncate_>>, size_t> const & sMap,
                   const char * pairFilePath)
{
    out.resize(qMap.size());

    std::ifstream fin(pairFilePath, std::ios_base::in | std::ios_base::binary);
    auto fit = directionIterator(fin, Input());

    String<char, Alloc<Truncate_>> qBuf;
    String<char, Alloc<Truncate_>> sBuf;
    size_t qInd;
    size_t sInd;
    while (!atEnd(fit))
    {
        clear(qBuf);
        clear(sBuf);
        readUntil(qBuf, fit, IsWhitespace());
        skipOne(fit, IsSpace());
        readLine(sBuf, fit);

        try
        {
            qInd = qMap.at(qBuf);
        } catch (std::out_of_range & e)
        {
            std::cerr << "ERROR: ID " << qBuf << " not found in query-map.\n";
            continue;
//             return -1;
        }

        try
        {
            sInd = sMap.at(sBuf);
        } catch (std::out_of_range & e)
        {
            std::cerr << "ERROR: ID " << sBuf << " not found in subject-map.\n";
            continue;
//             return -1;
        }
//         std::cout << "qind: " << qInd << "\t sind: " << sInd << std::endl;
        out.at(qInd).push_back(sInd);
    }

//     for (auto const & v : out)
//     {
//         for (size_t e : v)
//             std::cout << e << ", ";
//         if (length(v) > 0)
//             std::cout << std::endl;
//     }

    fin.close();
}

template <typename TAlignRow0_,
          typename TAlignRow1_,
          typename TPos_,
          typename TQId_,
          typename TSId_>
inline void
swap(BlastMatch<TAlignRow0_, TAlignRow1_, TPos_, TQId_, TSId_> & lhs,
     BlastMatch<TAlignRow0_, TAlignRow1_, TPos_, TQId_, TSId_> & rhs)
{
    std::swap(lhs._n_qId, rhs._n_qId);
    std::swap(lhs._n_sId, rhs._n_sId);

    swap(lhs.qId, rhs.qId);
    swap(lhs.sId, rhs.sId);

    std::swap(lhs.qStart, rhs.qStart);
    std::swap(lhs.qEnd, rhs.qEnd);
    std::swap(lhs.sStart, rhs.sStart);
    std::swap(lhs.sEnd, rhs.sEnd);

    std::swap(lhs.qLength, rhs.qLength);
    std::swap(lhs.sLength, rhs.sLength);

    std::swap(lhs.qFrameShift, rhs.qFrameShift);
    std::swap(lhs.sFrameShift, rhs.sFrameShift);

    std::swap(lhs.eValue, rhs.eValue);
    std::swap(lhs.bitScore, rhs.bitScore);


    lhs.alignStats = rhs.alignStats;

    swap(lhs.alignRow0, rhs.alignRow0);
    swap(lhs.alignRow1, rhs.alignRow1);
}



