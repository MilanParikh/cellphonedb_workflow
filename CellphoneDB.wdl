version 1.0

workflow cellphonedb {
    input {
    	String output_directory
        File anndata_file
        File annotations_file
        #cellphonedb parameters
        String counts_data = 'hgnc_symbol'
        Int n_iter = 1000
        Float threshold = 0.1
        Boolean subsampling = false
        Boolean subsampling_log = false
        Int subsampling_num_pc = 100
        Int subsampling_num_cells = 0
        Float pvalue = 0.05
        #general parameters
        Int cpu = 4
        String memory = "32G"
        String docker = "mparikhbroad/cellphonedb:latest"
        Int preemptible = 2
    }

    String output_directory_stripped = sub(output_directory, "/+$", "")

    call run_statistical_analysis {
        input:
            output_dir = output_directory_stripped,
            anndata_file = anndata_file,
            annotations_file = annotations_file,
            counts_data = counts_data,
            n_iter = n_iter,
            threshold = threshold,
            pvalue = pvalue,
            subsampling = subsampling,
            subsampling_log = subsampling_log,
            subsampling_num_pc = subsampling_num_pc,
            subsampling_num_cells = subsampling_num_cells,
            cpu=cpu,
            memory=memory,
            docker=docker,
            preemptible=preemptible
    }

    output {
        File pvalues_file = run_statistical_analysis.pvalues_file
        File means_file = run_statistical_analysis.means_file
        File significant_mean_file = run_statistical_analysis.significant_mean_file
        File deconvoluted_file = run_statistical_analysis.deconvoluted_file
    }
}

task run_statistical_analysis {

    input {
        String output_dir
        File anndata_file
        File annotations_file
        String counts_data
        Int n_iter
        Float threshold
        Boolean subsampling
        Boolean subsampling_log
        Int subsampling_num_pc
        Int subsampling_num_cells
        Float pvalue
        String memory
        Int cpu
        String docker
        Int preemptible
    }

    command <<<
        set -e

        mkdir -p outputs

        python <<CODE
        from subprocess import check_call
        import os
        
        annotations_file = "~{annotations_file}"
        anndata_file = "~{anndata_file}"
        counts_data = "~{counts_data}"
        pvalue = ~{pvalue}
        threshold = ~{threshold}
        n_iter = ~{n_iter}

        subsampling = ~{true='True' false='False' subsampling}
        subsampling_log = "~{true='true' false='false' subsampling_log}"
        subsampling_num_pc = "~{subsampling_num_pc}"
        subsampling_num_cells = ~{subsampling_num_cells}

        cpu = ~{cpu}

        run_command = ['cellphonedb', 'method', 'statistical_analysis', annotations_file, anndata_file, 
                        '--outputs-path', 'outputs', 
                        '--counts-data', counts_data, 
                        '--pvalue', str(pvalue),
                        '--threshold', str(threshold),
                        '--iterations', str(n_iter),
                        '--threads', str(cpu)]

        if(subsampling):
            run_command.append('--subsampling')
            run_command.append('--subsampling-log')
            run_combine.append(subsampling_log)
            run_command.append('--subsampling-num-pc')
            run_combine.append(subsampling_num_pc)
            if(subsampling_num_cells > 0) :
                run_command.append('--subsampling-num-cells')
                run_combine.append(str(subsampling_num_cells))

        print(' '.join(run_command), flush=True)
        check_call(run_command)
        CODE

        gsutil -m rsync -r outputs ~{output_dir}
    >>>

    output {
        File pvalues_file = 'outputs/pvalues.txt'
        File means_file = 'outputs/means.txt'
        File significant_mean_file = 'outputs/significant_means.txt'
        File deconvoluted_file = 'outputs/deconvoluted.txt'
    }

    runtime {
        docker: docker
        memory: memory
        bootDiskSizeGb: 12
        disks: "local-disk " + ceil(size(anndata_file, "GB")*2) + " HDD"
        cpu: cpu
        preemptible: preemptible
    }

}