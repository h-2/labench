#include <unordered_map>
#include <future>

#include "silverstandard.hpp"

using namespace seqan;

template <BlastProgram prog>
int
realMain(const char * q, const char * s, const char * p, const char * o);

// PROGRAMMODE qFile sFile pairFile outFile
int main(int argc, char **argv)
{

    if (argc != 6)
    {
        //TODO
        return -1;
    }



    if (std::string(argv[1]) == "BLASTN")
        realMain<BlastProgram::BLASTN>(argv[2], argv[3], argv[4], argv[5]);
    else if (std::string(argv[1]) == "BLASTP")
        realMain<BlastProgram::BLASTP>(argv[2], argv[3], argv[4], argv[5]);
    else if (std::string(argv[1]) == "BLASTX")
        realMain<BlastProgram::BLASTX>(argv[2], argv[3], argv[4], argv[5]);
    else if (std::string(argv[1]) == "TBLASTN")
        realMain<BlastProgram::TBLASTN>(argv[2], argv[3], argv[4], argv[5]);
    else if (std::string(argv[1]) == "TBLASTX")
        realMain<BlastProgram::TBLASTX>(argv[2], argv[3], argv[4], argv[5]);
    else
    {
        std::cerr <<  "bad Program mode selected.\n";
        return 1;
    }

}

template <BlastProgram prog>
int
realMain(const char * q, const char * s, const char * p, const char * o)
{
    using TIdSet        = StringSet<String<char, Alloc<Truncate_>>>;
    using TId           = typename Value<TIdSet>::Type;
    using TSeqs         = StringSet<String<TransAlph<prog>>, Owner<ConcatDirect<>>>;
    using TOrigQrySeqs  = StringSet<String<OrigQryAlph<prog>>, Owner<ConcatDirect<>>>;
    using TOrigSubjSeqs = StringSet<String<OrigSubjAlph<prog>>, Owner<ConcatDirect<>>>;
    using TMap          = std::unordered_map<String<char, Alloc<Truncate_>>, size_t>;

    SeqFileIn qryFile{q};
    SeqFileIn subjFile{s};

    TIdSet qryIds;
    TIdSet subjIds;

    TSeqs qrySeqs;
    TSeqs subjSeqs;

    std::vector<std::vector<size_t>> queryToSubjects;

    std::vector<size_t> origQryLengths;

    size_t numAlignments = 0;

    std::cout << "Reading files and creating hash tables... ";

    {
        TOrigQrySeqs origQrySeqs;
        TOrigSubjSeqs origSubjSeqs;

        TMap qryMap;
        TMap subjMap;

        auto qryReadFuture = std::async(std::launch::async, [&] ()
        {
            std::cout << "qrf start..." << std::endl;
            myReadRecords(qryIds, origQrySeqs, qryFile);

            origQryLengths.resize(length(origQrySeqs));
            SEQAN_OMP_PRAGMA(simd)
            for (uint32_t i = 0; i < length(origQryLengths); ++i)
                origQryLengths[i] = origQrySeqs.limits[i + 1] - origQrySeqs.limits[i];
            std::cout << "qrf end." << std::endl;
        });

        auto subjReadFuture = std::async(std::launch::async, [&] ()
        {
            std::cout << "srf start..." << std::endl;
            myReadRecords(subjIds, origSubjSeqs, subjFile);
            std::cout << "srf end." << std::endl;
        });

        auto qryTransFuture = std::async(std::launch::async, [&] ()
        {
            qryReadFuture.wait();
            std::cout << "qtf start..." << std::endl;
            translateOrSwap(qrySeqs, origQrySeqs);
            std::cout << "qtf stop." << std::endl;
        });

        auto qryHashFuture = std::async(std::launch::async, [&] ()
        {
            qryReadFuture.wait();
            std::cout << "qhf start..." << std::endl;
            hashIds(qryMap, qryIds);
            std::cout << "qhf stop." << std::endl;
        });

        auto subjTransFuture = std::async(std::launch::async, [&] ()
        {
            subjReadFuture.wait();
            std::cout << "stf start..." << std::endl;
            translateOrSwap(subjSeqs, origSubjSeqs);
            std::cout << "stf stop." << std::endl;
        });

        auto subjHashFuture = std::async(std::launch::async, [&] ()
        {
            subjReadFuture.wait();
            std::cout << "shf start..." << std::endl;
            hashIds(subjMap, subjIds);
            std::cout << "shf stop." << std::endl;
        });

        auto pairHashFuture = std::async(std::launch::async, [&] ()
        {
            qryHashFuture.wait();
            subjHashFuture.wait();
            std::cout << "phf start..." << std::endl;
            readPairsAndAssign(queryToSubjects, numAlignments, qryMap, subjMap, p);
            std::cout << "phf stop." << std::endl;
        });


        // destruction of futures guarantees completion of threads
    }

    std::cout << "done.\n\n"
              << "Total number of query sequences:            " << length(qryIds) << '\n'
              << "Total number of subject sequences:          " << length(subjIds) << '\n'
              << "Selected number of align's to be computed:  " << numAlignments  << '\n'
              << std::endl;

    using TString       = decltype(qrySeqs[0]);
    using TGaps         = Gaps<TString, ArrayGaps>;
    using TBlastMatch   = BlastMatch<TGaps, TGaps, uint32_t, TId, TId>;
    using TBlastRecord  = BlastRecord<TBlastMatch>;
    using TContext      = BlastIOContext<Blosum62, prog>;

    BlastTabularFileOut<TContext> outfile(o);

    // set gap parameters in blast notation
    setScoreGapOpenBlast(context(outfile).scoringScheme, -11);
    setScoreGapExtend(context(outfile).scoringScheme, -1);
    SEQAN_ASSERT(isValid(context(outfile).scoringScheme));

    // set the database properties in the context
    context(outfile).dbName = o;
    context(outfile).dbTotalLength = length(concat(subjSeqs));
    context(outfile).dbNumberOfSeqs = length(subjSeqs);

    writeHeader(outfile); // write file header

    size_t percent = 0;
    std::cout << "Computing and writing alignments:\n"
              << "0%  10%  20%  30%  40%  50%  60%  70%  80%  90%  100%\n|" << std::flush;

    size_t g_q = 0;
    SEQAN_OMP_PRAGMA(parallel for)
    for (size_t q = 0; q < length(qryIds); ++q)
    {

        if (queryToSubjects[q].size() > 0)
        {
            TBlastRecord r(qryIds[q]);
            r.qLength = length(origQryLengths[q]);

            for (size_t s : queryToSubjects[q])
            {
                appendValue(r.matches, TBlastMatch(qryIds[q], subjIds[s]));
                TBlastMatch & mFinal = back(r.matches);
                // choose temporary high value
                mFinal.eValue = std::numeric_limits<decltype(mFinal.eValue)>::max();

                for (size_t qf = 0; qf < qNumFrames(prog); ++qf)
                {
                    for (size_t sf = 0; sf < sNumFrames(prog); ++sf)
                    {
                        TBlastMatch m(qryIds[q], subjIds[s]);

                        auto const & qSeq = qrySeqs[q * qNumFrames(prog) + qf];
                        auto const & sSeq = subjSeqs[s * sNumFrames(prog) + sf];

                        assignSource(m.alignRow0, qSeq);
                        assignSource(m.alignRow1, sSeq);

                        localAlignment(m.alignRow0, m.alignRow1, seqanScheme(context(outfile).scoringScheme));

                        m.qStart = beginPosition(m.alignRow0);
                        m.qEnd   = endPosition(m.alignRow0);
                        m.sStart = beginPosition(m.alignRow1);
                        m.sEnd   = endPosition(m.alignRow1);

                        m.qLength = length(qSeq);
                        m.sLength = length(sSeq);

                        computeAlignmentStats(m, context(outfile));
                        computeBitScore(m, context(outfile));
                        computeEValue(m, context(outfile));

                        if (m.eValue < mFinal.eValue)
                            swap(m, mFinal);
                    }
                }
            }

            if (length(r.matches) > 0)
            {
                r.matches.sort();

                SEQAN_OMP_PRAGMA(critical(fileWrite))
                {
                    writeRecord(outfile, r);
                }

            }
        }

        SEQAN_OMP_PRAGMA(atomic)
        ++g_q;

        if (getThreadId == 0)
            printProgressBar(percent, (g_q * 100) / length(qryIds));
    }

    writeFooter(outfile);

    return 0;
}
