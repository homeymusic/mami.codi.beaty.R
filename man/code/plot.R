smoothing_file = '../code/smooth_2d_gaussian.cpp'
if (file.exists(smoothing_file)) {
  Rcpp::sourceCpp(smoothing_file)
} else {
  Rcpp::sourceCpp('./man/code/smooth_2d_gaussian.cpp')
}
smoothed <- function(x,val,sigma=0.2) {
  y = rep(0.0, times = length(x))
  smooth_2d_gaussian(
    data_x   = x,
    data_y   = y,
    data_val = val,
    probe_x  = x,
    probe_y  = y,
    sigma_x  = sigma,
    sigma_y  = sigma
  )
}
colors_homey <- list(
  'minor'             = '#8AC5FF',
  'neutral'           = '#FF5500',
  'major'             = '#FFB000',
  'periodicity'       = '#AF7AC5',
  'roughness'         = '#74DE7E',
  'behavioral'        = '#AAAAAA',
  'other_models'      = '#DDDDDD',
  'background'        = '#000000',
  'foreground'        = '#333333',
  'highlight'         = '#BBBBBB',
  'gray'              = '#C0C0C0',
  'subtle_foreground' = '#7F745A'
)
colors_homey$time = colors_homey$major
colors_homey$mami.codi.beaty = colors_homey$neutral
colors_homey$space = colors_homey$minor
colors_homey$HarrisonPearce2018=colors_homey$other_models
colors_homey$HutchinsonKnopoff1978Revised=colors_homey$other_models

color_factor_mami <- function(x,column_name) {
  cut(x[[column_name]],c(-Inf,-1e-6,1e-6,Inf),labels=c("minor","neutral","major"))
}

color_factor_ropey <- function(x,column_name) {
  cut(x[[column_name]],c(-Inf,-1e-6,1e-6,Inf),labels=c("periodicity","neutral","roughness"))
}

theme_homey <- function(aspect.ratio=NULL){
  font <- "Helvetica"   #assign font family up front

  ggplot2::theme_minimal()

  ggplot2::`%+replace%`  #replace elements we want to change

  ggplot2::theme(
    plot.title = ggplot2::element_text(color=colors_homey$foreground),
    axis.title = ggplot2::element_text(color=colors_homey$foreground),
    axis.text = ggplot2::element_text(color=colors_homey$foreground),
    axis.ticks = ggplot2::element_blank(),
    plot.background = ggplot2::element_rect(fill = colors_homey$highlight),
    panel.background = ggplot2::element_rect(fill = colors_homey$background),
    panel.grid.major = ggplot2::element_line(color = colors_homey$foreground, linewidth=0.2),
    panel.grid.minor = ggplot2::element_line(color = colors_homey$foreground, linewidth=0.1, linetype ="dashed"),
    legend.background = ggplot2::element_rect(fill = colors_homey$light_neutral),
    legend.key = ggplot2::element_rect(fill = colors_homey$background, color = NA),
    legend.position='bottom',
    aspect.ratio = aspect.ratio,
  )
}
theme_homey_minimal <- function(aspect.ratio=NULL){
  font <- "Helvetica"   #assign font family up front

  ggplot2::theme_minimal()

  ggplot2::`%+replace%`  #replace elements we want to change

  ggplot2::theme(
    plot.title = ggplot2::element_blank(),
    axis.title = ggplot2::element_blank(),
    axis.text = ggplot2::element_blank(),
    axis.ticks = ggplot2::element_blank(),
    plot.background = ggplot2::element_blank(),
    panel.background = ggplot2::element_rect(fill = colors_homey$background),
    panel.grid.major = ggplot2::element_line(color = colors_homey$foreground, linewidth=0.2),
    panel.grid.minor = ggplot2::element_line(color = colors_homey$foreground, linewidth=0.05, linetype ="dashed"),
    legend.background = ggplot2::element_blank(),
    legend.key = ggplot2::element_blank(),
    aspect.ratio = aspect.ratio
  )
}
plot_mami.codi <- function(chords, title='', chords_to_label=NULL,include_labels=F,
                           include_path=FALSE, aspect.ratio=NULL,
                           minimal=F) {

  if (is_null(chords_to_label)) {
    chords_to_label = chords
  }

  ggplot2::ggplot(chords, ggplot2::aes(x = .data$majorness,
                                       y = .data$consonance)) +
    ggplot2::geom_vline(xintercept = 0, color = colors_homey$neutral) +
    ggplot2::geom_point(shape=21, stroke=NA, size=1,
                        ggplot2::aes(fill=color_factor_mami(chords,'majorness'))) +
    ggplot2::scale_fill_manual(values=color_values_homey(), guide="none") +
    {if (include_path) {
      ggplot2::geom_path(
        ggplot2::aes(group=1,
                     color=color_factor_mami(chords,'majorness')),
        arrow = grid::arrow(length = grid::unit(0.1, "inches"),
                            ends = "last", type = "closed")
      )
    }} +
    {  if (include_labels) {
      ggrepel::geom_text_repel(data=chords_to_label,
                               ggplot2::aes(label=label,
                                            color=color_factor_mami(
                                              chords_to_label,'majorness')),
                               segment.color = colors_homey$subtle_foreground,
                               max.overlaps = Inf,
                               family='Arial Unicode MS')}} +
    ggplot2::scale_color_manual(values=color_values_homey(), guide='none') +
    ggplot2::ggtitle(title) +
    ggplot2::scale_x_continuous(
      expand = ggplot2::expansion(mult = 0.2),
      limits=c((0-max(abs(chords$majorness))),
               (0+max(abs(chords$majorness))))) +
    {if (minimal) theme_homey_minimal(aspect.ratio=aspect.ratio) else theme_homey(aspect.ratio=aspect.ratio)}
}
plot_smoothed_mami.codi <- function(chords, title='', chords_to_label=NULL,
                                    include_path=FALSE, aspect.ratio=NULL,
                                    minimal=F, sigma=0.25) {

  chords$smoothed_consonance = smoothed(chords$semitone,
                                        chords$consonance,
                                        sigma)

  chords = chords %>% dplyr::filter(semitone %in% 0:12)

  if (is.null(chords_to_label)) {
    chords_to_label = chords
  }

  ggplot2::ggplot(chords, ggplot2::aes(x = majorness,
                                       y = smoothed_consonance)) +
    ggplot2::geom_vline(xintercept = 0, color = colors_homey$neutral) +
    ggplot2::geom_point(shape=21, stroke=NA, size=1,
                        ggplot2::aes(fill=color_factor_mami(chords,'majorness'))) +
    ggplot2::scale_fill_manual(values=color_values_homey(), guide="none") +
    {if (include_path) {
      ggplot2::geom_path(
        ggplot2::aes(group=1,
                     color=color_factor_mami(chords,'majorness')),
        arrow = grid::arrow(length = grid::unit(0.1, "inches"),
                            ends = "last", type = "closed")
      )
    }} +
    ggrepel::geom_text_repel(data=chords_to_label,
                             ggplot2::aes(label=label,
                                          color=color_factor_mami(
                                            chords_to_label,'majorness')),
                             segment.color = colors_homey$subtle_foreground,
                             max.overlaps = Inf) +
    ggplot2::scale_color_manual(values=color_values_homey(), guide='none') +
    ggplot2::ggtitle(title) +
    ggplot2::scale_x_continuous(
      expand = ggplot2::expansion(mult = 0.2),
      limits=c((0-max(abs(chords$majorness))),
               (0+max(abs(chords$majorness))))) +
    {if (minimal) theme_homey_minimal(aspect.ratio=aspect.ratio) else theme_homey(aspect.ratio=aspect.ratio)}
}
plot_dilo.dihi <- function(chords, title, chords_to_label=NULL,
                           tonic_index=1, include_abline=F, aspect.ratio=NULL,
                           minimal=F) {
  if (is.null(chords_to_label)) {
    chords_to_label = chords
  }
  slope = chords$space_consonance[tonic_index] / chords$period_consonance[tonic_index]
  ggplot2::ggplot(chords, ggplot2::aes(x = .data$period_consonance,
                                       y = .data$space_consonance)) +
    { if(include_abline) ggplot2::geom_abline(slope = slope, color = colors_homey$neutral) } +
    ggplot2::geom_point(shape=21, stroke=NA, size=0.5, fill=colors_homey$neutral) +
    ggrepel::geom_text_repel(data=chords_to_label, color=colors_homey$neutral,
                             ggplot2::aes(label=label),
                             segment.color = colors_homey$subtle_foreground,
                             max.overlaps = Inf,
                             family='Arial Unicode MS') +
    ggplot2::scale_color_manual(guide='none') +
    ggplot2::ggtitle(title) +
    ggplot2::scale_x_continuous(
      limits=c(0,max(c(chords$period_consonance,chords$space_consonance)))) +
    {if (minimal) theme_homey_minimal(aspect.ratio=aspect.ratio) else theme_homey(aspect.ratio=aspect.ratio)}
}
plot_cofreq.cowave <- function(chords, title, chords_to_label=NULL,
                               tonic_index=1, include_abline=T, aspect.ratio=NULL,
                               minimal=F, include_labels=F) {
  if (is.null(chords_to_label)) {
    chords_to_label = chords
  }
  slope = chords$space_consonance[tonic_index] / chords$time_consonance[tonic_index]
  ggplot2::ggplot(chords, ggplot2::aes(x = .data$time_consonance,
                                       y = .data$space_consonance)) +
    { if(include_abline) ggplot2::geom_abline(slope = slope, color = colors_homey$neutral) } +
    ggplot2::geom_point(shape=21, stroke=NA, size=0.5, fill=colors_homey$neutral) +
    { if (include_labels)
      ggrepel::geom_text_repel(data=chords_to_label, color=colors_homey$neutral,
                               ggplot2::aes(label=label),
                               segment.color = colors_homey$subtle_foreground,
                               max.overlaps = Inf,
                               family='Arial Unicode MS')} +
    ggplot2::scale_color_manual(guide='none') +
    ggplot2::ggtitle(title) +
    # ggplot2::coord_fixed() +
    # ggplot2::scale_x_continuous(
    #   limits=c(min(c(chords$time_consonance,chords$space_consonance)),
    #            max(c(chords$time_consonance,chords$space_consonance)))) +
    {if (minimal) theme_homey_minimal(aspect.ratio=aspect.ratio) else theme_homey(aspect.ratio=aspect.ratio)}
}

plot_error_hist <- function(errors, bins=21, signal, variance, title_expr) {
  px = pretty(c(-variance, errors, variance))
  n_pts <- length(errors)

  title_call <- substitute(title_expr)
  full_title <- bquote(
    .(title_call) ~ " with " * N == .(format(n_pts, big.mark=","))  *  " and " ~ bins == .(bins)
  )
  ggplot2::ggplot(tibble::tibble(errors), ggplot2::aes(errors)) +
    ggplot2::geom_histogram(
      fill = colors_homey[signal],
      bins = bins
    ) +
    ggplot2::scale_x_continuous(
      breaks = px,
      limits = range(px)
    ) +
    ggplot2::geom_vline(
      xintercept = c(-variance, variance),
      color=colors_homey$highlight,
      linetype = 'dotted'
    ) +
    ggplot2::annotate(
      x=-variance,
      y=+Inf,
      label=round(-variance,5),
      vjust=2,
      geom='label',
      fill=colors_homey$neutral,
      color=colors_homey$background
    ) +
    ggplot2::annotate(
      x=variance,
      y=+Inf,
      label=round(variance,5),
      vjust=2,
      geom='label',
      fill=colors_homey$neutral,
      color=colors_homey$background
    ) +
    ggplot2::ggtitle(full_title) +
    theme_homey()
}

integer_semitones <- function(semitones) {
  unique(semitones[floor(semitones) == semitones])
}

plot_semitone_codi <- function(chords, title='', sigma=0.2,
                                         goal=NULL,
                                         black_vlines=c(),gray_vlines=c(),
                                         xlab='Semitone',
                                         ylab='Consonance (Z-Score)') {

  chords$smoothed_consonance_z = smoothed(chords$semitone,
                                          chords$consonance_z,
                                          sigma)

  ggplot2::ggplot(chords, ggplot2::aes(x = .data$semitone,
                                       y = .data$consonance_z)) +
    ggplot2::geom_vline(xintercept = black_vlines, color=colors_homey$highlight) +
    ggplot2::geom_vline(xintercept = gray_vlines,color=colors_homey$highlight,linetype = 'dotted') +
    ggplot2::geom_point(shape=21, stroke=NA, size=1,
                        alpha    = 0.4,
                        fill=colors_homey$neutral) +
    ggplot2::geom_line(data=chords,
                       ggplot2::aes(y = smoothed_consonance_z,
                                    color='mami.codi.beaty',
                                    group=1), linewidth = 1) +
    {if (!is.null(goal))
      ggplot2::geom_line(data=goal,
                         ggplot2::aes(x = semitone,
                                      y = consonance,
                                      color = 'behavioral'
                         ), linewidth = 0.5)} +
    ggplot2::scale_fill_manual(values=unlist(colors_homey), guide="none") +
    ggplot2::scale_color_manual(values=unlist(colors_homey)) +
    ggplot2::ggtitle(title) +
    ggplot2::scale_x_continuous(breaks = -15:15, minor_breaks = c()) +
    ggplot2::ylab(ylab) +
    ggplot2::xlab(xlab) +
    ggplot2::labs(color = NULL) +
    theme_homey()
}

plot_semitone_codi_with_mami <- function(chords, title='', sigma=0.2,
                               goal=NULL,
                               black_vlines=c(),gray_vlines=c(),
                               xlab='Semitone',
                               ylab='Consonance (Z-Score)') {

  chords$smoothed_consonance_z = smoothed(chords$semitone,
                                          chords$consonance_z,
                                          sigma)

  ggplot2::ggplot(chords, ggplot2::aes(x = .data$semitone,
                                       y = .data$consonance_z)) +
    ggplot2::geom_vline(xintercept = black_vlines, color=colors_homey$highlight) +
    ggplot2::geom_vline(xintercept = gray_vlines,color=colors_homey$highlight,linetype = 'dotted') +
    ggplot2::geom_point(shape=21, stroke=NA, size=1,
                        alpha    = 0.4,
                        ggplot2::aes(fill=color_factor_mami(chords,'majorness'))) +
    ggplot2::geom_line(data=chords,
                       ggplot2::aes(x = semitone,
                                    y = smoothed_consonance_z,
                                    color=color_factor_mami(chords,'majorness'),
                                    group=1), linewidth = 1) +
    {if (!is.null(goal))
      ggplot2::geom_line(data=goal,
                         ggplot2::aes(x = semitone,
                                      y = consonance,
                                      color = 'behavioral'
                         ), linewidth = 0.5)} +
    ggplot2::scale_fill_manual(values=unlist(colors_homey), guide="none") +
    ggplot2::scale_color_manual(values=unlist(colors_homey)) +
    ggplot2::ggtitle(title) +
    ggplot2::scale_x_continuous(breaks = -15:15, minor_breaks = c()) +
    ggplot2::ylab(ylab) +
    ggplot2::xlab(xlab) +
    ggplot2::labs(color = NULL) +
    theme_homey()
}

plot_semitone_codi_with_rope <- function(chords, title='', sigma=0.2,
                                         goal=NULL,
                                         black_vlines=c(),gray_vlines=c(),
                                         xlab='Semitone',
                                         ylab='Consonance (Z-Score)') {

  chords$smoothed_consonance_z = smoothed(chords$semitone,
                                          chords$consonance_z,
                                          sigma)

  ggplot2::ggplot(chords, ggplot2::aes(x = .data$semitone,
                                       y = .data$consonance_z)) +
    ggplot2::geom_vline(xintercept = black_vlines, color=colors_homey$highlight) +
    ggplot2::geom_vline(xintercept = gray_vlines,color=colors_homey$highlight,linetype = 'dotted') +
    ggplot2::geom_point(shape=21, stroke=NA, size=1,
                        alpha    = 0.4,
                        ggplot2::aes(fill=color_factor_ropey(chords,'ropey'))) +
    ggplot2::geom_line(data=chords,
                       ggplot2::aes(x = semitone,
                                    y = smoothed_consonance_z,
                                    color=color_factor_ropey(chords,'ropey'),
                                    group=1), linewidth = 1) +
    {if (!is.null(goal))
      ggplot2::geom_line(data=goal,
                         ggplot2::aes(x = semitone,
                                      y = consonance,
                                      color = 'behavioral'
                         ), linewidth = 0.5)} +
    ggplot2::scale_fill_manual(values=unlist(colors_homey), guide="none") +
    ggplot2::scale_color_manual(values=unlist(colors_homey)) +
    ggplot2::ggtitle(title) +
    ggplot2::scale_x_continuous(breaks = -15:15, minor_breaks = c()) +
    ggplot2::ylab(ylab) +
    ggplot2::xlab(xlab) +
    ggplot2::labs(color = NULL) +
    theme_homey()
}

plot_semitone_error_sum <- function(chords, title='', include_line=T, sigma=0.2,
                                    include_points=T,
                                    include_linear_regression = F, goal=NULL,
                                    black_vlines=c(),gray_vlines=c(),
                                    xlab='Semitone',
                                    ylab='Relative Uncertainty') {

  whole_semitones = integer_semitones(chords$semitone)

  chords$smoothed_error_sum_z = smoothed(chords$semitone,
                                         chords$error_sum_z,
                                         sigma)

  ggplot2::ggplot(chords, ggplot2::aes(x = .data$semitone,
                                       y = .data$error_sum_z)) +
    ggplot2::geom_vline(xintercept = black_vlines, color=colors_homey$highlight) +
    ggplot2::geom_vline(xintercept = gray_vlines,color=colors_homey$highlight,linetype = 'dotted') +
    { if (include_points)
      ggplot2::geom_point(shape=21, stroke=NA, size=1,
                          ggplot2::aes(fill=color_factor_mami(chords,'majorness')))
    } +
    { if (include_linear_regression) ggplot2::stat_smooth(method=lm)} +
    { if (include_line)
      ggplot2::geom_line(data=chords,
                         ggplot2::aes(x = semitone,
                                      y = smoothed_error_sum_z,
                                      color=color_factor_mami(chords,'majorness'),
                                      group=1), linewidth = 1)} +
    {if (!is.null(goal))
      ggplot2::geom_line(data=goal,
                         ggplot2::aes(x = semitone,
                                      y = consonance,
                                      color = 'behavioral'
                         ), linewidth = 0.5)} +
    ggplot2::scale_fill_manual(values=color_values_homey(), guide="none") +
    ggplot2::scale_color_manual(values=color_values_homey()) +
    ggplot2::ggtitle(title) +
    ggplot2::scale_x_continuous(breaks = -15:15, minor_breaks = c()) +
    ggplot2::ylab(ylab) +
    ggplot2::xlab(xlab) +
    ggplot2::labs(color = NULL) +
    theme_homey()
}


plot_semitone_thomaes_function <- function(chords, title='', include_line=T, sigma=0.2,
                                           include_points=T,
                                           goal=NULL,
                                           black_vlines=c(),gray_vlines=c(),
                                           xlab='Semitone',
                                           ylab='Consonance (Z-Score)') {

  whole_semitones = integer_semitones(chords$semitone)

  chords$smoothed_thomaes_function_z = smoothed(chords$semitone,
                                                chords$thomaes_function_z,
                                                sigma)

  ggplot2::ggplot(chords, ggplot2::aes(x = .data$semitone,
                                       y = .data$thomaes_function_z)) +
    ggplot2::geom_vline(xintercept = black_vlines, color=colors_homey$highlight) +
    ggplot2::geom_vline(xintercept = gray_vlines,color=colors_homey$highlight,linetype = 'dotted') +
    { if (include_points)
      ggplot2::geom_point(shape=21, stroke=NA, size=1,
                          ggplot2::aes(fill=color_factor_mami(chords,'majorness')))
    } +
    { if (include_line)
      ggplot2::geom_line(data=chords,
                         ggplot2::aes(x = semitone,
                                      y = smoothed_thomaes_function_z,
                                      color=color_factor_mami(chords,'majorness'),
                                      group=1), linewidth = 1)} +
    {if (!is.null(goal))
      ggplot2::geom_line(data=goal,
                         ggplot2::aes(x = semitone,
                                      y = consonance,
                                      color = 'behavioral'
                         ), linewidth = 0.5)} +
    ggplot2::scale_fill_manual(values=color_values_homey(), guide="none") +
    ggplot2::scale_color_manual(values=color_values_homey()) +
    ggplot2::ggtitle(title) +
    ggplot2::scale_x_continuous(breaks = whole_semitones,
                                minor_breaks = c()) + # Removed `breaks` argument to auto-generate tick labels
    ggplot2::ylab(ylab) +
    ggplot2::xlab(xlab) +
    ggplot2::labs(color = NULL) +
    theme_homey()
}

plot_semitone_roughness_space_time <- function(chords, title='', sigma=0.2,
                                               black_vlines=c(),gray_vlines=c(),
                                               xlab='Semitone',
                                               ylab='Log2 of Total Stern Brocot Depth (Z-Score)') {

  chords$smoothed_roughness = smoothed(chords$semitone,
                                            chords$roughness_z,
                                            sigma)

  chords$smoothed_time_roughness = smoothed(chords$semitone,
                                            chords$time_roughness_z,
                                            sigma)

  chords$smoothed_space_roughness = smoothed(chords$semitone,
                                             chords$space_roughness_z,
                                             sigma)

  ggplot2::ggplot(chords, ggplot2::aes(x = .data$semitone)) +
    ggplot2::geom_vline(xintercept = black_vlines, color=colors_homey$highlight) +
    ggplot2::geom_vline(xintercept = gray_vlines,color=colors_homey$highlight,linetype = 'dotted') +
      ggplot2::geom_point(ggplot2::aes(y = .data$time_roughness_z),
                          shape=21, stroke=NA, size=1,
                          fill=colors_homey$time,
                          alpha    = 0.4
      ) +
      ggplot2::geom_point(ggplot2::aes(y = .data$space_roughness_z),
                          shape=21, stroke=NA, size=1,
                          fill=colors_homey$space,
                          alpha    = 0.4
      ) +
      ggplot2::geom_line(
        ggplot2::aes(
          y     = .data$smoothed_time_roughness,
          color = "time"
        ),
        linewidth = 1
      ) +
      ggplot2::geom_line(
        ggplot2::aes(
          y     = .data$smoothed_space_roughness,
          color = "space"
        ),
        linewidth = 1
      ) +
    ggplot2::geom_line(ggplot2::aes(y = .data$smoothed_roughness,
                                    color = 'roughness'
                       ), linewidth = 0.5) +
    ggplot2::ggtitle(title) +
    ggplot2::scale_x_continuous(breaks = -15:15, minor_breaks = c()) +
    ggplot2::guides(col = ggplot2::guide_legend()) +
    ggplot2::ylab(ylab) +
    ggplot2::xlab(xlab) +
    ggplot2::scale_color_manual(
      values=unlist(colors_homey),
      breaks=c('space', 'time', 'roughness')) +
    ggplot2::labs(color = NULL) +
    theme_homey()
}

plot_semitone_stern_brocot_depth <- function(chords, title='', include_line=T, sigma=0.2,
                                             include_points=T,
                                             goal=NULL,
                                             black_vlines=c(),gray_vlines=c(),
                                             xlab='Semitone',
                                             ylab='Negative Stern Brocot Depth  (Z-Score)') {

  whole_semitones = integer_semitones(chords$semitone)

  chords$smoothed_stern_brocot_depth_z = smoothed(chords$semitone,
                                                  chords$stern_brocot_depth_z,
                                                  sigma)

  ggplot2::ggplot(chords, ggplot2::aes(x = .data$semitone)) +
    ggplot2::geom_vline(xintercept = black_vlines, color=colors_homey$highlight) +
    ggplot2::geom_vline(xintercept = gray_vlines,color=colors_homey$highlight,linetype = 'dotted') +
    { if (include_points)
      ggplot2::geom_point(shape = 21, stroke = NA, size = 1, fill = colors_homey$green)
    } +
    { if (include_line)
      ggplot2::geom_line(data=chords,
                         ggplot2::aes(x = semitone,
                                      y = smoothed_stern_brocot_depth_z,
                                      color = 'sb_depth',
                                      group=1), linewidth = 1)} +
    {if (!is.null(goal))
      ggplot2::geom_line(data=goal,
                         ggplot2::aes(x = semitone,
                                      y = consonance,
                                      color = 'behavioral'
                         ), linewidth = 0.5)} +
    ggplot2::scale_fill_manual(values=color_values_homey(), guide="none") +
    ggplot2::scale_color_manual(values=color_values_homey()) +
    ggplot2::ggtitle(title) +
    ggplot2::scale_x_continuous(breaks = -15:15, minor_breaks = c()) +
    ggplot2::ylab(ylab) +
    ggplot2::xlab(xlab) +
    ggplot2::labs(color = NULL) +
    theme_homey()
}


plot_semitone_stern_brocot_depth_diff <- function(chords, title='', include_line=T, sigma=0.2,
                                                  include_points=T,
                                                  goal=NULL,
                                                  black_vlines=c(),gray_vlines=c(),
                                                  xlab='Semitone',
                                                  ylab='Stern Brocot Depth Diff (Z-Score)') {

  whole_semitones = integer_semitones(chords$semitone)

  chords$smoothed_stern_brocot_depth_diff_z = smoothed(chords$semitone,
                                                       chords$stern_brocot_depth_diff_z,
                                                       sigma)

  ggplot2::ggplot(chords, ggplot2::aes(x = .data$semitone,
                                       y = .data$stern_brocot_depth_diff_z)) +
    ggplot2::geom_vline(xintercept = black_vlines, color=colors_homey$highlight) +
    ggplot2::geom_vline(xintercept = gray_vlines,color=colors_homey$highlight,linetype = 'dotted') +
    { if (include_points)
      ggplot2::geom_point(shape = 21, stroke = NA, size = 1, fill = colors_homey$green)
    } +
    { if (include_line)
      ggplot2::geom_line(data=chords,
                         ggplot2::aes(x = semitone,
                                      y = smoothed_stern_brocot_depth_diff_z,
                                      color = 'sb_depth',
                                      group=1), linewidth = 1)} +
    {if (!is.null(goal))
      ggplot2::geom_line(data=goal,
                         ggplot2::aes(x = semitone,
                                      y = consonance,
                                      color = 'behavioral'
                         ), linewidth = 0.5)} +
    ggplot2::scale_fill_manual(values=color_values_homey(), guide="none") +
    ggplot2::scale_color_manual(values=color_values_homey()) +
    ggplot2::ggtitle(title) +
    ggplot2::scale_x_continuous(breaks = -15:15, minor_breaks = c()) +
    ggplot2::ylab(ylab) +
    ggplot2::xlab(xlab) +
    ggplot2::labs(color = NULL) +
    theme_homey()
}
plot_semitone_euclids_orchard_height <- function(chords, title='', include_line=T, sigma=0.2,
                                                 include_points=T,
                                                 goal=NULL,
                                                 black_vlines=c(),gray_vlines=c(),
                                                 xlab='Semitone',
                                                 ylab='Consonance (Z-Score)') {

  whole_semitones = integer_semitones(chords$semitone)

  chords$smoothed_euclids_orchard_height_z = smoothed(chords$semitone,
                                                      chords$euclids_orchard_height_z,
                                                      sigma)

  ggplot2::ggplot(chords, ggplot2::aes(x = .data$semitone,
                                       y = .data$euclids_orchard_height_z)) +
    ggplot2::geom_vline(xintercept = black_vlines, color=colors_homey$highlight) +
    ggplot2::geom_vline(xintercept = gray_vlines,color=colors_homey$highlight,linetype = 'dotted') +
    { if (include_points)
      ggplot2::geom_point(shape=21, stroke=NA, size=1,
                          ggplot2::aes(fill=color_factor_mami(chords,'majorness')))
    } +
    { if (include_line)
      ggplot2::geom_line(data=chords,
                         ggplot2::aes(x = semitone,
                                      y = smoothed_euclids_orchard_height_z,
                                      color=color_factor_mami(chords,'majorness'),
                                      group=1), linewidth = 1)} +
    {if (!is.null(goal))
      ggplot2::geom_line(data=goal,
                         ggplot2::aes(x = semitone,
                                      y = consonance,
                                      color = 'behavioral'
                         ), linewidth = 0.5)} +
    ggplot2::scale_fill_manual(values=color_values_homey(), guide="none") +
    ggplot2::scale_color_manual(values=color_values_homey()) +
    ggplot2::ggtitle(title) +
    ggplot2::scale_x_continuous(breaks = whole_semitones,
                                minor_breaks = c()) + # Removed `breaks` argument to auto-generate tick labels
    ggplot2::ylab(ylab) +
    ggplot2::xlab(xlab) +
    ggplot2::labs(color = NULL) +
    theme_homey()
}

plot_semitone_mami <- function(chords, title='', include_line=T, sigma=0.2,
                               include_points=T,
                               include_linear_regression = F, goal=NULL,
                               black_vlines=c(),gray_vlines=c(),
                               xlab='Semitone',
                               ylab='Major-Minor (Z-Score)') {

  whole_semitones = integer_semitones(chords$semitone)

  chords$smoothed_majorness_z = smoothed(chords$semitone,
                                         chords$majorness_z,
                                         sigma)

  ggplot2::ggplot(chords, ggplot2::aes(x = .data$semitone,
                                       y = .data$majorness_z)) +
    ggplot2::geom_vline(xintercept = black_vlines, color=colors_homey$highlight) +
    ggplot2::geom_vline(xintercept = gray_vlines,color=colors_homey$highlight,linetype = 'dotted') +
    { if (include_points)
      ggplot2::geom_point(shape=21, stroke=NA, size=1,
                          ggplot2::aes(fill=color_factor_mami(chords,'majorness')))
    } +
    { if (include_linear_regression) ggplot2::stat_smooth(method=lm)} +
    { if (include_line)
      ggplot2::geom_line(data=chords,
                         ggplot2::aes(x = semitone,
                                      y = smoothed_majorness_z,
                                      color=color_factor_mami(chords,'majorness'),
                                      group=1), linewidth = 1)} +
    {if (!is.null(goal))
      ggplot2::geom_line(data=goal,
                         ggplot2::aes(x = semitone,
                                      y = consonance,
                                      color = 'behavioral'
                         ), linewidth = 0.5)} +
    ggplot2::scale_fill_manual(values=color_values_homey(), guide="none") +
    ggplot2::scale_color_manual(values=color_values_homey()) +
    ggplot2::ggtitle(title) +
    ggplot2::scale_x_continuous(breaks = -15:15, minor_breaks = c()) +
    ggplot2::ylab(ylab) +
    ggplot2::xlab(xlab) +
    ggplot2::labs(color = NULL) +
    theme_homey()
}



plot_semitone_mami_vert <- function(chords, title='', include_line=T, sigma=0.2,
                                    include_points=T,
                                    goal=NULL,
                                    black_vlines=c(),gray_vlines=c(),
                                    ylab='Semitone',
                                    xlab='Major-Minor (Z-Score)') {

  chords$smoothed_majorness_z = smoothed(chords$semitone,
                                         chords$majorness_z,
                                         sigma)

  # 2) assemble every x-value we’ll plot (raw majorness, smoothed, plus goal if present)
  all_x <- c(
    chords$majorness,
    chords$smoothed_majorness_z,
    if (!is.null(goal)) goal$consonance else NULL
  )

  # 3) find the maximum absolute x and build symmetric limits
  max_x    <- max(abs(all_x), na.rm = TRUE)
  x_limits <- c(-max_x, max_x)

  ggplot2::ggplot(chords, ggplot2::aes(y = .data$semitone)) +
    ggplot2::geom_hline(yintercept = black_vlines, color=colors_homey$highlight) +
    ggplot2::geom_hline(yintercept = gray_vlines,color=colors_homey$highlight,linetype = 'dotted') +
    { if (include_points)
      ggplot2::geom_point(shape=21, stroke=NA, size=1,
                          ggplot2::aes(
                            x = .data$majorness,
                            fill=color_factor_mami(chords,'majorness')
                          ))
    } +
    { if (include_line)
      ggplot2::geom_path(
        data=goal,
        ggplot2::aes(x = chords$smoothed_majorness_z,
                     color=color_factor_mami(chords,'majorness'),
                     group=1), linewidth = 1)} +
    {if (!is.null(goal))
      ggplot2::geom_path(data=goal,
                         ggplot2::aes(y = semitone,
                                      x = consonance,
                                      color = 'behavioral',
                                      group=1
                         ), linewidth = 0.5)} +

    ggplot2::scale_x_continuous(
      limits       = x_limits,
      breaks       = seq(floor(-max_x), ceiling(max_x), by = 1),
      minor_breaks = NULL,
      expand       = ggplot2::expansion(mult = c(0, 0))
    ) +
    ggplot2::scale_fill_manual(values=color_values_homey(), guide="none") +
    ggplot2::scale_color_manual(values=color_values_homey()) +
    ggplot2::ggtitle(title) +
    ggplot2::scale_y_continuous(breaks = 0:15, minor_breaks = c()) +
    ggplot2::ylab(ylab) +
    ggplot2::xlab(xlab) +
    ggplot2::labs(color = NULL) +
    theme_homey()
}

plot_semitone_error_sum_space_time  <- function(chords, title='', include_line=T, sigma=0.2,
                                                dashed_minor = F, include_points=T,
                                                include_linear_regression = F, goal=NULL,
                                                black_vlines=c(),gray_vlines=c(),
                                                xlab='Semitone',
                                                ylab='Relative Uncertainty') {

  whole_semitones = integer_semitones(chords$semitone)

  chords$smoothed_time_error_sum  = smoothed(chords$semitone,
                                             chords$time_error_sum,
                                             sigma)
  chords$smoothed_space_error_sum = smoothed(chords$semitone,
                                             chords$space_error_sum,
                                             sigma)

  mean_theoretical = mean(c(chords$smoothed_time_error_sum,
                            chords$smoothed_space_error_sum))

  linetype_for_minor = if (dashed_minor) {'dashed'} else {'solid'}

  ggplot2::ggplot(chords, ggplot2::aes(x = .data$semitone)) +
    ggplot2::geom_vline(xintercept = black_vlines, color=colors_homey$highlight) +
    ggplot2::geom_vline(xintercept = gray_vlines,color='gray44',linetype = 'dotted') +
    { if (include_points)
      ggplot2::geom_point(ggplot2::aes(y = .data$time_error_sum),
                          shape=21, stroke=NA, size=1,
                          fill=colors_homey$major)
    } +
    { if (include_points)
      ggplot2::geom_point(ggplot2::aes(y = .data$space_error_sum),
                          shape=21, stroke=NA, size=1,
                          fill=colors_homey$minor)
    } +
    ggplot2::geom_line(ggplot2::aes(
      y = .data$smoothed_time_error_sum,
      color = 'time'),
      linewidth = 1) +
    ggplot2::geom_line(ggplot2::aes(
      y = .data$smoothed_space_error_sum,
      color = 'space'),
      linewidth = 1,
      linetype = linetype_for_minor) +
    {if (!is.null(goal))
      ggplot2::geom_line(data=goal,
                         ggplot2::aes(x = semitone,
                                      y = consonance + mean_theoretical,
                                      color = 'behavioral',
                                      group=1), linewidth = 0.5)} +
    ggplot2::ggtitle(title) +
    ggplot2::scale_x_continuous(breaks = -15:15, minor_breaks = c()) +
    ggplot2::guides(col = ggplot2::guide_legend()) +
    ggplot2::ylab(ylab) +
    ggplot2::xlab(xlab) +
    ggplot2::scale_color_manual(
      values=space_time_colors(),
      breaks=c('space', 'time', 'behavioral')) +
    ggplot2::labs(color = NULL) +
    theme_homey()
}

plot_semitone_periodicity_space_time <- function(chords, title='',  sigma=0.2,
                                                 black_vlines=c(),gray_vlines=c(),
                                                 xlab='Semitone',
                                                 ylab='Log2 of Cycle Length (Z-Score)') {

  chords$smoothed_periodicity  = smoothed(chords$semitone,
                                          chords$periodicity_z,
                                          sigma)
  chords$smoothed_time_periodicity  = smoothed(chords$semitone,
                                               chords$time_periodicity_z,
                                               sigma)
  chords$smoothed_space_periodicity = smoothed(chords$semitone,
                                               chords$space_periodicity_z,
                                               sigma)

  ggplot2::ggplot(chords, ggplot2::aes(x = .data$semitone)) +
    ggplot2::geom_vline(xintercept = black_vlines, color=colors_homey$highlight) +
    ggplot2::geom_vline(xintercept = gray_vlines,color='gray44',linetype = 'dotted') +
    ggplot2::geom_point(ggplot2::aes(y = .data$time_periodicity_z),
                        shape=21, stroke=NA, size=1,
                        alpha    = 0.4,
                        fill=colors_homey$time) +
    ggplot2::geom_point(ggplot2::aes(y = .data$space_periodicity_z),
                        shape=21, stroke=NA, size=1,
                        alpha    = 0.4,
                        fill=colors_homey$space) +
    ggplot2::geom_line(ggplot2::aes(
      y = .data$smoothed_time_periodicity,
      color = 'time'),
      linewidth = 1) +
    ggplot2::geom_line(ggplot2::aes(
      y = .data$smoothed_space_periodicity,
      color = 'space'),
      linewidth = 1) +
    ggplot2::geom_line(
      ggplot2::aes(y = .data$smoothed_periodicity,
                   color = 'periodicity',
                   group=1), linewidth = 0.5) +
    ggplot2::ggtitle(title) +
    ggplot2::scale_x_continuous(breaks = -15:15, minor_breaks = c()) +
    ggplot2::guides(col = ggplot2::guide_legend()) +
    ggplot2::ylab(ylab) +
    ggplot2::xlab(xlab) +
    ggplot2::scale_color_manual(
      values=unlist(colors_homey),
      breaks=c('space', 'time', 'behavioral', 'periodicity')) +
    ggplot2::labs(color = NULL) +
    theme_homey()
}

plot_semitone_periodicity_roughness <- function(chords, title='', sigma=0.2,
                                                goal=NULL,
                                                black_vlines=c(),gray_vlines=c(),
                                                xlab='Semitone',
                                                ylab='Periodicity & Roughness (Z-Score)') {

  chords$smoothed_periodicity  = smoothed(chords$semitone,
                                               chords$periodicity_z,
                                               sigma)

  chords$smoothed_roughness = smoothed(chords$semitone,
                                            chords$roughness_z,
                                            sigma)

  ggplot2::ggplot(chords, ggplot2::aes(x = .data$semitone)) +
    ggplot2::geom_vline(xintercept = black_vlines, color=colors_homey$highlight) +
    ggplot2::geom_vline(xintercept = gray_vlines,color='gray44',linetype = 'dotted') +

    ggplot2::geom_point(ggplot2::aes(y = .data$periodicity_z), shape=21, stroke=NA, size=1, alpha = 0.4, fill = colors_homey$periodicity) +
    ggplot2::geom_point(ggplot2::aes(y = .data$roughness_z), shape=21, stroke=NA, size=1, alpha = 0.4, fill = colors_homey$roughness) +

    ggplot2::geom_line(ggplot2::aes(y = .data$smoothed_periodicity, color = 'periodicity'), linewidth = 1) +
    ggplot2::geom_line(ggplot2::aes(y = .data$smoothed_roughness, color = "roughness"), linewidth = 1) +

    {if (!is.null(goal))
      ggplot2::geom_line(data=goal,
                         ggplot2::aes(x = semitone,
                                      y = consonance,
                                      color = 'behavioral',
                                      group=1), linewidth = 0.5)} +
    ggplot2::ggtitle(title) +
    ggplot2::scale_x_continuous(breaks = -15:15, minor_breaks = c()) +
    ggplot2::guides(col = ggplot2::guide_legend()) +
    ggplot2::ylab(ylab) +
    ggplot2::xlab(xlab) +
    ggplot2::scale_fill_manual(
      values=unlist(colors_homey),
      breaks=c('periodicity', 'behavioral', 'roughness')) +
    ggplot2::scale_color_manual(
      values=unlist(colors_homey),
      breaks=c('periodicity', 'behavioral', 'roughness')) +
    ggplot2::labs(color = NULL) +
    theme_homey()
}

plot_semitone_periodicity_model_compare <- function(chords, title='', sigma=0.2,
                                                goal=NULL,model_name='',
                                                black_vlines=c(),gray_vlines=c(),
                                                xlab='Semitone',
                                                ylab='Periodicity (Z-Score)') {

  chords$smoothed_periodicity_z = smoothed(chords$semitone,
                                           chords$periodicity_z,
                                           sigma)

  ggplot2::ggplot(chords, ggplot2::aes(x = .data$semitone)) +
    ggplot2::geom_vline(xintercept = black_vlines, color=colors_homey$highlight) +
    ggplot2::geom_vline(xintercept = gray_vlines,color='gray44',linetype = 'dotted') +

    ggplot2::geom_line(ggplot2::aes(y = .data$smoothed_periodicity_z, color = 'periodicity'), linewidth = 1) +

    {if (!is.null(goal))
      ggplot2::geom_line(data=goal,
                         ggplot2::aes(x = semitone,
                                      y = consonance_z,
                                      color = model_name,
                                      group=1), linewidth = 0.5)} +
    ggplot2::ggtitle(title) +
    ggplot2::scale_x_continuous(breaks = -15:15, minor_breaks = c()) +
    ggplot2::guides(col = ggplot2::guide_legend()) +
    ggplot2::ylab(ylab) +
    ggplot2::xlab(xlab) +
    ggplot2::scale_color_manual(
      values=unlist(colors_homey),
      breaks=c('periodicity',  model_name)) +
    ggplot2::labs(color = NULL) +
    theme_homey()
}

plot_semitone_roughness_model_compare <- function(chords, title='', sigma=0.2,
                                                    goal=NULL,model_name='',
                                                    black_vlines=c(),gray_vlines=c(),
                                                    xlab='Semitone',
                                                    ylab='Roughness (Z-Score)') {

  chords$smoothed_roughness_z = smoothed(chords$semitone,
                                           chords$roughness_z,
                                           sigma)

  ggplot2::ggplot(chords, ggplot2::aes(x = .data$semitone)) +
    ggplot2::geom_vline(xintercept = black_vlines, color=colors_homey$highlight) +
    ggplot2::geom_vline(xintercept = gray_vlines,color='gray44',linetype = 'dotted') +

    ggplot2::geom_line(ggplot2::aes(y = .data$smoothed_roughness_z, color = 'roughness'), linewidth = 1) +

    {if (!is.null(goal))
      ggplot2::geom_line(data=goal,
                         ggplot2::aes(x = semitone,
                                      y = consonance_z,
                                      color = model_name,
                                      group=1), linewidth = 0.5)} +
    ggplot2::ggtitle(title) +
    ggplot2::scale_x_continuous(breaks = -15:15, minor_breaks = c()) +
    ggplot2::guides(col = ggplot2::guide_legend()) +
    ggplot2::ylab(ylab) +
    ggplot2::xlab(xlab) +
    ggplot2::scale_color_manual(
      values=unlist(colors_homey),
      breaks=c('roughness', model_name)) +
    ggplot2::labs(color = NULL) +
    theme_homey()
}

plot_semitone_space_time_beats <- function(chords, title='', include_line=T, sigma=0.2,
                                           dashed_minor = F,include_points=T,
                                           include_linear_regression = F, goal=NULL,
                                           black_vlines=c(),gray_vlines=c(),
                                           xlab='Semitone',
                                           ylab='Consonance') {

  whole_semitones = integer_semitones(chords$semitone)

  chords$smoothed_time_consonance  = smoothed(chords$semitone,
                                              chords$time_consonance,
                                              sigma)
  chords$smoothed_space_consonance = smoothed(chords$semitone,
                                              chords$space_consonance,
                                              sigma)

  chords$smoothed_time_beats_consonance  = smoothed(chords$semitone,
                                                    chords$time_beats_consonance,
                                                    sigma)
  chords$smoothed_space_beats_consonance = smoothed(chords$semitone,
                                                    chords$space_beats_consonance,
                                                    sigma)

  mean_theoretical = mean(c(chords$smoothed_time_consonance,
                            chords$smoothed_space_consonance,
                            chords$smoothed_time_beats_consonance,
                            chords$smoothed_space_beats_consonance))

  linetype_for_minor = if (dashed_minor) {'dashed'} else {'solid'}

  ggplot2::ggplot(chords, ggplot2::aes(x = .data$semitone)) +
    ggplot2::geom_vline(xintercept = black_vlines, color=colors_homey$highlight) +
    ggplot2::geom_vline(xintercept = gray_vlines,color='gray44',linetype = 'dotted') +
    { if (include_points)
      ggplot2::geom_point(ggplot2::aes(y = .data$time_consonance),
                          shape=21, stroke=NA, size=1,
                          fill=colors_homey$major)
    } +
    { if (include_points)
      ggplot2::geom_point(ggplot2::aes(y = .data$space_consonance),
                          shape=21, stroke=NA, size=1,
                          fill=colors_homey$minor)
    } +
    { if (include_points)
      ggplot2::geom_point(ggplot2::aes(y = .data$time_beats_consonance),
                          shape=21, stroke=NA, size=1,
                          fill=colors_homey$major)
    } +
    { if (include_points)
      ggplot2::geom_point(ggplot2::aes(y = .data$space_beats_consonance),
                          shape=21, stroke=NA, size=1,
                          fill=colors_homey$minor)
    } +
    ggplot2::geom_line(ggplot2::aes(
      y = .data$smoothed_time_consonance,
      color = 'time'),
      linewidth = 1,
      linetype = 'solid') +
    ggplot2::geom_line(ggplot2::aes(
      y = .data$smoothed_space_consonance,
      color = 'space'),
      linewidth = 1,
      linetype = 'solid') +
    ggplot2::geom_line(ggplot2::aes(
      y = .data$smoothed_time_beats_consonance,
      color = 'time'),
      linewidth = 1,
      linetype = 'dashed') +
    ggplot2::geom_line(ggplot2::aes(
      y = .data$smoothed_space_beats_consonance,
      color = 'space'),
      linewidth = 1,
      linetype = 'dashed') +
    {if (!is.null(goal))
      ggplot2::geom_line(data=goal,
                         ggplot2::aes(x = semitone,
                                      y = consonance + mean_theoretical,
                                      color = 'behavioral',
                                      group=1), linewidth = 0.5)} +
    ggplot2::ggtitle(title) +
    ggplot2::scale_x_continuous(breaks = whole_semitones,
                                minor_breaks = c()) +
    ggplot2::guides(col = ggplot2::guide_legend()) +
    ggplot2::ylab(ylab) +
    ggplot2::xlab(xlab) +
    ggplot2::scale_color_manual(
      values=space_time_colors(),
      breaks=c('space', 'time', 'behavioral')) +
    ggplot2::labs(color = NULL) +
    theme_homey()
}

plot_semitone_space <- function(chords, title='', include_line=T, sigma=0.2,
                                dashed_minor = F,include_points=T,
                                include_linear_regression = F, goal=NULL,
                                black_vlines=c(),gray_vlines=c()) {

  chords$smoothed_space_consonance = smoothed(chords$semitone,
                                              chords$space_consonance,
                                              sigma)

  linetype_for_minor = if (dashed_minor) {'dashed'} else {'solid'}

  ggplot2::ggplot(chords, ggplot2::aes(x = .data$semitone)) +
    ggplot2::geom_vline(xintercept = black_vlines, color=colors_homey$highlight) +
    ggplot2::geom_vline(xintercept = gray_vlines,color='gray44',linetype = 'dotted') +
    { if (include_points)
      ggplot2::geom_point(ggplot2::aes(y = .data$space_consonance),
                          shape=21, stroke=NA, size=1,
                          fill=colors_homey$minor)
    } +
    ggplot2::geom_line(ggplot2::aes(
      y = .data$smoothed_space_consonance,
      color = 'space'),
      linewidth = 1,
      linetype = linetype_for_minor) +
    ggplot2::ggtitle(title) +
    ggplot2::scale_x_continuous(breaks = 0:15,
                                minor_breaks = c()) +
    ggplot2::guides(col = ggplot2::guide_legend()) +
    ggplot2::ylab('space Consonance') +
    ggplot2::xlab('Semitone') +
    ggplot2::scale_color_manual(
      values=space_time_colors(),
      breaks=c('space', 'time', 'behavioral')) +
    ggplot2::labs(color = NULL) +
    theme_homey()
}

plot_semitone_time <- function(chords, title='', include_line=T, sigma=0.2,
                               dashed_minor = F,include_points=T,
                               include_linear_regression = F, goal=NULL,
                               black_vlines=c(),gray_vlines=c()) {

  chords$smoothed_time_consonance = smoothed(chords$semitone,
                                             chords$time_consonance,
                                             sigma)

  linetype_for_minor = if (dashed_minor) {'dashed'} else {'solid'}

  ggplot2::ggplot(chords, ggplot2::aes(x = .data$semitone)) +
    ggplot2::geom_vline(xintercept = black_vlines, color=colors_homey$highlight) +
    ggplot2::geom_vline(xintercept = gray_vlines,color='gray44',linetype = 'dotted') +
    { if (include_points)
      ggplot2::geom_point(ggplot2::aes(y = .data$time_consonance),
                          shape=21, stroke=NA, size=1,
                          fill=colors_homey$major)
    } +
    ggplot2::geom_line(ggplot2::aes(
      y = .data$smoothed_time_consonance,
      color = 'time'),
      linewidth = 1,
      linetype = linetype_for_minor) +
    ggplot2::ggtitle(title) +
    ggplot2::scale_x_continuous(breaks = 0:15,
                                minor_breaks = c()) +
    ggplot2::guides(col = ggplot2::guide_legend()) +
    ggplot2::ylab('time Consonance') +
    ggplot2::xlab('Semitone') +
    ggplot2::scale_color_manual(
      values=space_time_colors(),
      breaks=c('space', 'time', 'behavioral')) +
    ggplot2::labs(color = NULL) +
    theme_homey()
}
plot_semitone_co <- function(chords, title='') {
  time_semitone =chords$semitone %>% min
  space_semitone =chords$semitone %>% max
  ggplot2::ggplot(chords, ggplot2::aes(x = .data$semitone,
                                       y = .data$consonance)) +
    ggplot2::geom_point(color=colors_homey$neutral) +
    ggplot2::scale_x_continuous(breaks = seq(time_semitone,space_semitone),
                                minor_breaks = c()) +
    ggplot2::ggtitle(title) +
    theme_homey()
}
plot_semitone_space_uncertainty <- function(chords, title='') {
  time_semitone =chords$semitone %>% min
  space_semitone =chords$semitone %>% max
  ggplot2::ggplot(chords, ggplot2::aes(x = .data$semitone,
                                       y = .data$space_uncertainty)) +
    ggplot2::geom_point(color=colors_homey$neutral, size=0.5) +
    ggplot2::scale_x_continuous(breaks = seq(time_semitone,space_semitone),
                                minor_breaks = c()) +
    ggplot2::ggtitle(title) +
    theme_homey()
}
plot_semitone_rotation_angle <- function(chords, title='') {
  ggplot2::ggplot(chords, ggplot2::aes(x = .data$semitone,
                                       y = .data$rotation_angle * 180 / pi,1)) +
    ggplot2::geom_point(color=colors_homey$neutral, size=0.5) +
    ggplot2::scale_x_continuous(breaks = 0:15,
                                minor_breaks = c()) +
    ggplot2::ggtitle(title) +
    ggplot2::ylab('Rotation Angle (degs)') +
    theme_homey()
}
plot_semitone_registers <- function(chords, title='') {
  ggplot2::ggplot(chords, ggplot2::aes(x = .data$semitone)) +
    ggplot2::geom_point(color=colors_homey$minor, size=0.5,
                        ggplot2::aes(y = max(.data$frequencies[[1]]))) +
    ggplot2::geom_point(color=colors_homey$major, size=0.5,
                        ggplot2::aes(y = min(.data$frequencies[[1]]))) +
    ggplot2::geom_point(color=colors_homey$fundamental, size=0.0625,
                        ggplot2::aes(y = max(.data$frequencies[[1]]))) +
    ggplot2::geom_point(color=colors_homey$fundamental, size=0.0625,
                        ggplot2::aes(y = min(.data$frequencies[[1]]))) +
    ggplot2::scale_x_continuous(breaks = 0:15,
                                minor_breaks = c()) +
    ggplot2::scale_y_continuous(breaks=round(hrep::midi_to_freq(48)*2^(0:7),1),
                                minor_breaks=c(),
                                trans='log2') +
    ggplot2::ggtitle(title) +
    ggplot2::ylab('Ref Freqs & Tonic Timbre') +
    theme_homey()
}

plot_num_harmonics_deviation <- function(num_harmonics_deviation, title='') {
  num_harmonics = num_harmonics_deviation$num_harmonics
  ggplot2::ggplot(num_harmonics_deviation, ggplot2::aes(x = .data$num_harmonics)) +
    ggplot2::geom_point(ggplot2::aes(y = .data$candidate_deviation),
                        color=colors_homey$green, size=0.5) +
    ggplot2::geom_point(ggplot2::aes(y = .data$min),
                        color=colors_homey$major, size=0.5) +
    ggplot2::geom_point(ggplot2::aes(y = .data$median),
                        color=colors_homey$fundamental, size=0.5) +
    ggplot2::geom_point(ggplot2::aes(y = .data$max),
                        color=colors_homey$minor, size=0.5) +
    ggplot2::geom_point(ggplot2::aes(y = .data$range),
                        color=colors_homey$neutral, size=0.5) +
    ggplot2::scale_x_continuous(breaks = num_harmonics,
                                minor_breaks = c()) +
    ggplot2::ggtitle(title) +
    theme_homey()
}
plot_semitone_codi_grid <- function(theory, experiment,
                                    black_vlines=c(), gray_vlines=c(),
                                    include_points=T,
                                    title) {
  per_plot_labels = tidyr::expand_grid(
    space_uncertainty = theory$space_uncertainty %>% unique
  )
  per_plot_labels$label = per_plot_labels %>%
    purrr::pmap_vec(\(time_space_uncertainty,space_uncertainty) {
      tols = paste(
        'space_uncertainty:', space_uncertainty
      )
    })
  theory %>% ggplot2::ggplot(ggplot2::aes(x=semitone, y=z_score)) +
    ggplot2::geom_vline(xintercept = black_vlines, color='black') +
    ggplot2::geom_vline(xintercept = gray_vlines,color='gray44',linetype = 'dotted') +
    ggplot2::scale_fill_manual(values=color_values_homey(), guide="none") +
    ggplot2::geom_line(
      data=experiment,
      color    = colors_homey$neutral,
      ggplot2::aes(x = semitone, y = rating)) +
    ggplot2::geom_line(
      data=theory,
      ggplot2::aes(x = semitone, y = smooth,
                   group=1,
                   color=color_factor_mami(theory,'majorness'))) +
    { if (include_points)
      ggplot2::geom_point(shape=21, stroke=NA, size=1,
                          ggplot2::aes(fill=color_factor_mami(theory,'majorness')))
    } +
    ggplot2::scale_color_manual(values=color_values_homey(), guide='none') +
    ggplot2::geom_text(data=per_plot_labels, ggplot2::aes(x=-Inf,y=-Inf,label=label,
                                                          vjust="inward",hjust="inward")) +
    ggplot2::xlab(NULL) +
    ggplot2::ylab(NULL) +
    ggplot2::facet_grid(space_uncertainty ~ space_uncertainty, scales = 'free_y') +
    ggplot2::scale_x_continuous(breaks = c(),
                                minor_breaks = 0:15) +
    theme_homey()
}

plot_semitone_polar_codi_wrap <- function(theory, experiment,
                                          black_vlines=c(), gray_vlines=c(),
                                          title,ncols=12,
                                          include_points=T) {
  per_plot_labels = tidyr::expand_grid(
    space_uncertainty  = theory$space_uncertainty  %>% unique
  )
  per_plot_labels$label = per_plot_labels %>%
    purrr::pmap_vec(\(space_uncertainty) {
      tols = paste0('   space_uncertainty:', space_uncertainty)
    })
  theory %>% ggplot2::ggplot(ggplot2::aes(x=semitone, y=smooth)) +
    ggplot2::geom_vline(xintercept = black_vlines, color='black') +
    ggplot2::geom_vline(xintercept = gray_vlines,color='gray44',linetype = 'dotted') +
    {if (include_points)
      ggplot2::geom_point(data=theory, shape=21, stroke=NA, size=1,
                          ggplot2::aes(x = semitone, y = z_score,
                                       fill=color_factor_mami(theory,'polar_majorness')))} +
    ggplot2::scale_fill_manual(values=color_values_homey(), guide="none") +
    {if (!is.null(experiment)) {
      ggplot2::geom_line(
        data=experiment,
        color    = colors_homey$neutral,
        ggplot2::aes(x = semitone, y = consonance))}} +
    ggplot2::geom_line(
      data=theory,
      ggplot2::aes(x = semitone, y = smooth,
                   group=1,
                   color=color_factor_mami(theory,'polar_majorness'))) +
    ggplot2::scale_color_manual(values=color_values_homey(), guide='none') +
    ggplot2::geom_text(data=per_plot_labels, color=colors_homey$neutral,
                       ggplot2::aes(x=-Inf,y=-Inf,label=label,
                                    vjust="inward",hjust="inward")) +
    ggplot2::xlab(NULL) +
    ggplot2::ylab(NULL) +
    ggplot2::facet_wrap(~space_uncertainty,ncol=ncols,dir='v') +
    ggplot2::scale_x_continuous(breaks = c(),
                                minor_breaks = 0:15) +
    theme_homey()
}

plot_semitone_space_wrap <- function(theory,
                                     black_vlines=c(), gray_vlines=c(),
                                     title,ncols=1) {
  per_plot_labels = tidyr::expand_grid(
    space_uncertainty  = theory$space_uncertainty  %>% unique
  )
  per_plot_labels$label = per_plot_labels %>%
    purrr::pmap_vec(\(space_uncertainty) {
      tols = paste0('   space_uncertainty:', space_uncertainty)
    })
  theory %>% ggplot2::ggplot(ggplot2::aes(x=semitone, y=smooth)) +
    ggplot2::geom_vline(xintercept = black_vlines, color='black') +
    ggplot2::geom_vline(xintercept = gray_vlines,color='gray44',linetype = 'dotted') +
    ggplot2::geom_point(data=theory, shape=21, stroke=NA, size=1,
                        fill=colors_homey$minor,
                        ggplot2::aes(x = semitone, y = space_consonance)) +
    ggplot2::geom_line(
      color=colors_homey$minor,
      data=theory,
      ggplot2::aes(x = semitone, y = smooth,
                   group=1)) +
    ggplot2::geom_text(data=per_plot_labels, color=colors_homey$neutral,
                       ggplot2::aes(x=-Inf,y=-Inf,label=label,
                                    vjust="inward",hjust="inward")) +
    ggplot2::xlab(NULL) +
    ggplot2::ylab(NULL) +
    ggplot2::facet_wrap(~space_uncertainty,ncol=ncols,dir='v') +
    ggplot2::scale_x_continuous(breaks = c(),
                                minor_breaks = 0:15) +
    theme_homey()
}
plot_semitone_time_wrap <- function(theory,
                                    black_vlines=c(), gray_vlines=c(),
                                    title,ncols=1) {
  per_plot_labels = tidyr::expand_grid(
    space_uncertainty  = theory$space_uncertainty  %>% unique
  )
  per_plot_labels$label = per_plot_labels %>%
    purrr::pmap_vec(\(space_uncertainty) {
      tols = paste0('   space_uncertainty:', space_uncertainty)
    })
  theory %>% ggplot2::ggplot(ggplot2::aes(x=semitone, y=smooth)) +
    ggplot2::geom_vline(xintercept = black_vlines, color='black') +
    ggplot2::geom_vline(xintercept = gray_vlines,color='gray44',linetype = 'dotted') +
    ggplot2::geom_point(data=theory, shape=21, stroke=NA, size=1,
                        fill=colors_homey$major,
                        ggplot2::aes(x = semitone, y = time_consonance)) +
    ggplot2::geom_line(
      color=colors_homey$major,
      data=theory,
      ggplot2::aes(x = semitone, y = smooth,
                   group=1)) +
    ggplot2::geom_text(data=per_plot_labels, color=colors_homey$neutral,
                       ggplot2::aes(x=-Inf,y=-Inf,label=label,
                                    vjust="inward",hjust="inward")) +
    ggplot2::xlab(NULL) +
    ggplot2::ylab(NULL) +
    ggplot2::facet_wrap(~space_uncertainty,ncol=ncols,dir='v') +
    ggplot2::scale_x_continuous(breaks = c(),
                                minor_breaks = 0:15) +
    theme_homey()
}

plot_semitone_mami_wrap <- function(theory, experiment,
                                    black_vlines=c(), gray_vlines=c(),
                                    title,ncols=12) {
  per_plot_labels = tidyr::expand_grid(
    space_uncertainty  = theory$space_uncertainty  %>% unique,
  )
  per_plot_labels$label = per_plot_labels %>%
    purrr::pmap_vec(\(space_uncertainty) {
      tols = paste0('  ', space_uncertainty)
    })
  theory %>% ggplot2::ggplot(ggplot2::aes(x=semitone, y=majorness)) +
    ggplot2::geom_vline(xintercept = black_vlines, color='black') +
    ggplot2::geom_vline(xintercept = gray_vlines,color='gray44',linetype = 'dotted') +
    ggplot2::geom_point(data=theory, shape=21, stroke=NA, size=1,
                        ggplot2::aes(x = semitone, y = majorness,
                                     fill=color_factor_mami(theory,'majorness'))) +
    ggplot2::scale_fill_manual(values=color_values_homey(), guide="none") +
    ggplot2::scale_color_manual(values=color_values_homey(), guide='none') +
    ggplot2::geom_text(data=per_plot_labels, color=colors_homey$neutral,
                       ggplot2::aes(x=-Inf,y=-Inf,label=label,
                                    vjust="inward",hjust="inward")) +
    ggplot2::xlab(NULL) +
    ggplot2::ylab(NULL) +
    ggplot2::facet_wrap(~space_uncertainty,ncol=ncols,dir='v') +
    ggplot2::scale_x_continuous(breaks = c(),
                                minor_breaks = 0:15) +
    theme_homey()
}
plot_semitone_behavioral_codi <- function(experiment_raw,
                                          experiment_smooth,
                                          title='',
                                          sigma=0.2,
                                          black_vlines=c(),
                                          gray_vlines=c()) {
  experiment_raw$smoothed_consonance = smoothed(experiment_raw$semitone,
                                                experiment_raw$consonance_z,
                                                sigma)

  ggplot2::ggplot(experiment_raw, ggplot2::aes(x = .data$semitone,
                                               y = .data$consonance_z)) +
    ggplot2::geom_vline(xintercept = black_vlines, color=colors_homey$highlight) +
    ggplot2::geom_vline(xintercept = gray_vlines,color=colors_homey$highlight,linetype = 'dotted') +
    ggplot2::geom_point(shape=21, stroke=NA, size=1,
                        fill=colors_homey$highlight) +
    ggplot2::geom_line(data=experiment_smooth,
                       color    = colors_homey$subtle_foreground,
                       ggplot2::aes(x = semitone,
                                    y = consonance,
                                    group=1), linewidth = 0.5) +
    ggplot2::geom_line(data=experiment_raw,
                       color=colors_homey$fundamental,
                       ggplot2::aes(x = semitone,
                                    y = smoothed_consonance,
                                    group=1), linewidth = 1) +
    ggplot2::scale_fill_manual(values=color_values_homey(), guide="none") +
    ggplot2::scale_color_manual(values=color_values_homey(), guide='none') +
    ggplot2::ggtitle(title) +
    ggplot2::scale_x_continuous(breaks = 0:15,
                                minor_breaks = c()) +
    ggplot2::ylab('Consonance-consonance Z-Score') +
    theme_homey()
}

plot_semitone_codi_raw <- function(theory_raw,
                                   experiment_raw,
                                   sigma=0.2,
                                   black_vlines=c(),
                                   gray_vlines=c(),
                                   title='') {

  theory_raw$smoothed_consonance = smoothed(theory_raw$semitone,
                                            theory_raw$consonance_z,
                                            sigma)

  experiment_raw$smoothed_consonance = smoothed(experiment_raw$semitone,
                                                experiment_raw$consonance_z,
                                                sigma)

  ggplot2::ggplot(theory_raw, ggplot2::aes(x = .data$semitone,
                                           y = .data$consonance_z)) +
    ggplot2::geom_vline(xintercept = black_vlines, color=colors_homey$highlight) +
    ggplot2::geom_vline(xintercept = gray_vlines,color=colors_homey$highlight,linetype = 'dotted') +
    ggplot2::geom_point(shape=21, stroke=NA, size=1,
                        ggplot2::aes(fill=color_factor_mami(theory_raw,'majorness'))) +
    ggplot2::geom_line(data=theory_raw,
                       ggplot2::aes(x = semitone,
                                    y = smoothed_consonance,
                                    color=color_factor_mami(theory_raw,'majorness'),
                                    group=1), linewidth = 0.65) +
    ggplot2::geom_line(data=experiment_raw,
                       color=colors_homey$neutral,
                       ggplot2::aes(x = semitone,
                                    y = smoothed_consonance,
                                    group=1), linewidth = 0.65) +
    ggplot2::scale_fill_manual(values=color_values_homey(), guide="none") +
    ggplot2::scale_color_manual(values=color_values_homey(), guide='none') +
    ggplot2::ggtitle(title) +
    ggplot2::scale_x_continuous(breaks = 0:15,
                                minor_breaks = c()) +
    ggplot2::ylab('Consonance-consonance Z-Score') +
    theme_homey()
}
plot_semitone_codi_smooth <- function(chords, title='', include_line=T,
                                      sigma=0.2,sigma2=2.0,
                                      include_points=T,
                                      include_linear_regression = F, goal=NULL,
                                      black_vlines=c(),gray_vlines=c()) {
  chords$smoothed_consonance = smoothed(chords$semitone,
                                        chords$consonance,
                                        sigma)

  chords$smoothed2.consonance = smoothed(chords$semitone,
                                         chords$consonance,
                                         sigma2)

  ggplot2::ggplot(chords, ggplot2::aes(x = .data$semitone,
                                       y = .data$consonance)) +
    ggplot2::geom_vline(xintercept = black_vlines, color=colors_homey$highlight) +
    ggplot2::geom_vline(xintercept = gray_vlines,color=colors_homey$highlight,linetype = 'dotted') +
    { if (include_points)
      ggplot2::geom_point(shape=21, stroke=NA, size=1,
                          ggplot2::aes(fill=color_factor_mami(chords,'majorness')))
    } +
    { if (include_linear_regression) ggplot2::stat_smooth(method=lm)} +
    { if (include_line)
      ggplot2::geom_line(data=chords,
                         ggplot2::aes(x = semitone,
                                      y = smoothed_consonance,
                                      color=color_factor_mami(chords,'majorness'),
                                      group=1), linewidth = 1)} +
    {if (!is.null(goal))
      ggplot2::geom_line(data=goal,
                         color    = colors_homey$neutral,
                         ggplot2::aes(x = semitone,
                                      y = consonance,
                                      group=1), linewidth = 0.5)} +
    ggplot2::geom_line(data=chords,
                       color=colors_homey$green,
                       ggplot2::aes(x = semitone,
                                    y = smoothed2.consonance,
                                    group=1), linewidth = 1) +
    ggplot2::scale_fill_manual(values=color_values_homey(), guide="none") +
    ggplot2::scale_color_manual(values=color_values_homey(), guide='none') +
    ggplot2::ggtitle(title) +
    ggplot2::scale_x_continuous(breaks = -15:15,
                                minor_breaks = c()) +
    ggplot2::ylab('Consonance-consonance') +
    theme_homey()
}

plot_periodicity <- function(ratios, lcd, dimension,
                             c_sound = NULL,
                             relative = T) {

  if (dimension=='wavelength') {
    fill_color   = colors_homey$minor
    border_color = colors_homey$minor_dark
    max_tone = ratios$tone %>% max()
    max_ratio = ratios %>% dplyr::arrange(dplyr::desc(tone)) %>% dplyr::slice(1)
    max_num = max_ratio$num
    max_den = max_ratio$den
  } else if (dimension=='frequency') {
    fill_color   = colors_homey$major
    border_color = colors_homey$major_dark
    min_tone = ratios$tone %>% min()
  }
  brickwork = ratios %>% purrr::pmap_dfr(\( index,
                                            num,
                                            den,
                                            tone,
                                            freq,
                                            midi) {
    course_of_bricks <- tibble::tibble(
      xmin = numeric(),
      xmax = numeric(),
      ymin = numeric(),
      ymax = numeric()
    )
    if (dimension=='wavelength') {
      if (relative) {
        ratio_to_max = (num / den) / (max_num / max_den)
        brick_count  = floor(lcd / ratio_to_max)
        brick_width  = max_tone * ratio_to_max
      } else {
        brick_width = tone
        brick_count = 1
      }
    } else if (dimension=='frequency') {
      if (relative) {
        brick_width = 1 / tone
        brick_count = floor(lcd * (num / den))
      } else {
        brick_width = 1 / tone
        brick_count = 1
      }
    }
    for (brick in 0:(brick_count-1)) {
      course_of_bricks = course_of_bricks %>% tibble::add_row(
        xmin = brick*brick_width,
        xmax = brick*brick_width + brick_width,
        ymin = midi - 0.5,
        ymax = midi + 0.5
      )
    }
    course_of_bricks
  })
  if (dimension=='wavelength') {
    xlab = bquote('Wavelength'~(m))
    scaled_label = scales::label_number(scale = 1e+00)
  } else if (dimension=='frequency') {
    xlab = bquote('Period'~(ms))
    scaled_label = scales::label_number(scale = 1e03)
  }
  ggplot2::ggplot(brickwork, ggplot2::aes(
    xmin=xmin,
    xmax=xmax,
    ymin=ymin,
    ymax=ymax
  )) +
    ggplot2::geom_rect(fill=fill_color, color=border_color) +
    ggplot2::xlab(xlab) +
    ggplot2::ylab("MIDI") +
    ggplot2::scale_x_continuous(labels = scaled_label) +
    theme_homey()
}

plot_semitone_codi_wrap_amp <- function(theory, experiment,
                                        black_vlines=c(), gray_vlines=c(),
                                        title,ncols=12,
                                        include_points=T) {
  per_plot_labels = tidyr::expand_grid(
    amplitude  = theory$amplitude  %>% unique
  )
  per_plot_labels$label = per_plot_labels %>%
    purrr::pmap_vec(\(amplitude) {
      tols = paste0('   amplitude:', amplitude)
    })
  theory %>% ggplot2::ggplot(ggplot2::aes(x=semitone, y=smooth)) +
    ggplot2::geom_vline(xintercept = black_vlines, color='black') +
    ggplot2::geom_vline(xintercept = gray_vlines,color='gray44',linetype = 'dotted') +
    {if (include_points)
      ggplot2::geom_point(data=theory, shape=21, stroke=NA, size=1,
                          ggplot2::aes(x = semitone, y = z_score,
                                       fill=color_factor_mami(theory,'majorness')))} +
    ggplot2::scale_fill_manual(values=color_values_homey(), guide="none") +
    ggplot2::geom_line(
      data=experiment,
      color    = colors_homey$neutral,
      ggplot2::aes(x = semitone, y = consonance)) +
    ggplot2::geom_line(
      data=theory,
      ggplot2::aes(x = semitone, y = smooth,
                   group=1,
                   color=color_factor_mami(theory,'majorness'))) +
    ggplot2::scale_color_manual(values=color_values_homey(), guide='none') +
    ggplot2::geom_text(data=per_plot_labels, color=colors_homey$neutral,
                       ggplot2::aes(x=-Inf,y=-Inf,label=label,
                                    vjust="inward",hjust="inward")) +
    ggplot2::xlab(NULL) +
    ggplot2::ylab(NULL) +
    ggplot2::facet_wrap(~amplitude,ncol=ncols,dir='v') +
    ggplot2::scale_x_continuous(breaks = c(),
                                minor_breaks = 0:15) +
    theme_homey()
}
plot_semitone_space_wrap_amp <- function(theory,
                                         black_vlines=c(), gray_vlines=c(),
                                         title,ncols=1) {
  per_plot_labels = tidyr::expand_grid(
    amplitude  = theory$amplitude  %>% unique
  )
  per_plot_labels$label = per_plot_labels %>%
    purrr::pmap_vec(\(amplitude) {
      tols = paste0('   amplitude:', amplitude)
    })
  theory %>% ggplot2::ggplot(ggplot2::aes(x=semitone, y=smooth)) +
    ggplot2::geom_vline(xintercept = black_vlines, color='black') +
    ggplot2::geom_vline(xintercept = gray_vlines,color='gray44',linetype = 'dotted') +
    ggplot2::geom_point(data=theory, shape=21, stroke=NA, size=1,
                        fill=colors_homey$minor,
                        ggplot2::aes(x = semitone, y = space_consonance)) +
    ggplot2::geom_line(
      color=colors_homey$minor,
      data=theory,
      ggplot2::aes(x = semitone, y = smooth,
                   group=1)) +
    ggplot2::geom_text(data=per_plot_labels, color=colors_homey$neutral,
                       ggplot2::aes(x=-Inf,y=-Inf,label=label,
                                    vjust="inward",hjust="inward")) +
    ggplot2::xlab(NULL) +
    ggplot2::ylab(NULL) +
    ggplot2::facet_wrap(~amplitude,ncol=ncols,dir='v') +
    ggplot2::scale_x_continuous(breaks = c(),
                                minor_breaks = 0:15) +
    theme_homey()
}
plot_semitone_time_wrap_amp <- function(theory,
                                        black_vlines=c(), gray_vlines=c(),
                                        title,ncols=1) {
  per_plot_labels = tidyr::expand_grid(
    amplitude  = theory$amplitude  %>% unique
  )
  per_plot_labels$label = per_plot_labels %>%
    purrr::pmap_vec(\(amplitude) {
      tols = paste0('   amplitude:', amplitude)
    })
  theory %>% ggplot2::ggplot(ggplot2::aes(x=semitone, y=smooth)) +
    ggplot2::geom_vline(xintercept = black_vlines, color='black') +
    ggplot2::geom_vline(xintercept = gray_vlines,color='gray44',linetype = 'dotted') +
    ggplot2::geom_point(data=theory, shape=21, stroke=NA, size=1,
                        fill=colors_homey$major,
                        ggplot2::aes(x = semitone, y = time_consonance)) +
    ggplot2::geom_line(
      color=colors_homey$major,
      data=theory,
      ggplot2::aes(x = semitone, y = smooth,
                   group=1)) +
    ggplot2::geom_text(data=per_plot_labels, color=colors_homey$neutral,
                       ggplot2::aes(x=-Inf,y=-Inf,label=label,
                                    vjust="inward",hjust="inward")) +
    ggplot2::xlab(NULL) +
    ggplot2::ylab(NULL) +
    ggplot2::facet_wrap(~amplitude,ncol=ncols,dir='v') +
    ggplot2::scale_x_continuous(breaks = c(),
                                minor_breaks = 0:15) +
    theme_homey()
}

plot_semitone_energy_per_cycle <- function(chords, title = '', goal=NULL, include_line = F, sigma = 0.2,
                                           include_points = TRUE,
                                           black_vlines = c(), gray_vlines = c()) {

  # Smooth the beating metric
  chords$smoothed_energy_per_cycle_z <- smoothed(chords$semitone, chords$energy_per_cycle_z, sigma)

  # Plotting
  ggplot2::ggplot(chords, ggplot2::aes(x = .data$semitone, y = .data$energy_per_cycle_z)) +
    ggplot2::geom_vline(xintercept = black_vlines, color = colors_homey$highlight) +
    ggplot2::geom_vline(xintercept = gray_vlines, color = colors_homey$highlight, linetype = 'dotted') +
    { if (include_points)
      ggplot2::geom_point(shape = 21, stroke = NA, size = 1, fill = colors_homey$green)  # Set fill directly
    } +
    { if (include_line)

    { if (include_line)
      ggplot2::geom_line(data=chords,
                         ggplot2::aes(x = semitone,
                                      y = smoothed_energy_per_cycle_z,
                                      group=1), color = colors_homey$green_lighter, linewidth = 1)}
    } +
    {if (!is.null(goal))
      ggplot2::geom_line(data=goal,
                         ggplot2::aes(x = semitone,
                                      y = consonance),
                         color = colors_homey$neutral,
                         linewidth = 0.5)} +
    ggplot2::scale_fill_manual(values = color_values_homey(), guide = "none") +
    ggplot2::ggtitle(title) +
    ggplot2::scale_x_continuous(breaks = -15:15, minor_breaks = c()) +
    ggplot2::ylab('Negative Energy Per Cycle (log2)') +
    ggplot2::xlab('Semitone') +
    ggplot2::labs(color = NULL) +
    theme_homey()
}


plot_semitone_codi_wrap <- function(theory, experiment,
                                    black_vlines = c(), gray_vlines = c(),
                                    title, ncols = 12,
                                    include_points = TRUE) {
  per_plot_labels = tidyr::expand_grid(
    space_uncertainty = theory$space_uncertainty %>% unique
  )
  per_plot_labels$label = per_plot_labels %>%
    purrr::pmap_vec(\(space_uncertainty) {
      paste0('   space_uncertainty:', space_uncertainty)
    })

  theory %>% ggplot2::ggplot(ggplot2::aes(x = semitone, y = smooth)) +
    ggplot2::geom_vline(xintercept = black_vlines, color = 'black') +
    ggplot2::geom_vline(xintercept = gray_vlines, color = 'gray44', linetype = 'dotted') +
    {if (include_points)
      ggplot2::geom_point(data = theory, shape = 21, stroke = NA, size = 1,
                          ggplot2::aes(x = semitone, y = z_score,
                                       fill = color_factor_mami(theory, 'majorness')))} +
    ggplot2::scale_fill_manual(values = color_values_homey(), guide = "none") +
    {if (!is.null(experiment)) {
      ggplot2::geom_line(
        data = experiment,
        color = colors_homey$neutral,
        ggplot2::aes(x = semitone, y = consonance))
    }} +
    ggplot2::geom_line(
      data = theory,
      ggplot2::aes(x = semitone, y = smooth,
                   group = 1,
                   color = color_factor_mami(theory, 'majorness'))) +
    ggplot2::scale_color_manual(values = color_values_homey(), guide = 'none') +
    ggplot2::geom_text(data = per_plot_labels, color = colors_homey$neutral,
                       ggplot2::aes(x = -Inf, y = -Inf, label = label,
                                    vjust = "inward", hjust = "inward")) +
    ggplot2::xlab(NULL) +
    ggplot2::ylab(NULL) +
    ggplot2::scale_x_continuous() +  # Automatically generate x-axis labels
    ggplot2::facet_wrap(~space_uncertainty, ncol = ncols, dir = 'v',
                        scales = "free_y") +
    theme_homey()
}

plot_semitone_space_time_wrap <- function(theory,
                                          black_vlines=c(), gray_vlines=c(),
                                          title,ncols=1) {
  per_plot_labels = tidyr::expand_grid(
    space_uncertainty  = theory$space_uncertainty  %>% unique
  )
  per_plot_labels$label = per_plot_labels %>%
    purrr::pmap_vec(\(space_uncertainty) {
      paste0('   space_uncertainty:', space_uncertainty)
    })
  theory %>% ggplot2::ggplot(ggplot2::aes(x=semitone, y=smooth)) +
    ggplot2::geom_vline(xintercept = black_vlines, color='black') +
    ggplot2::geom_vline(xintercept = gray_vlines,color='gray44',linetype = 'dotted') +
    ggplot2::geom_point(data=theory, shape=21, stroke=NA, size=1,
                        fill=colors_homey$major,
                        ggplot2::aes(x = semitone, y = -time_dissonance)) +
    ggplot2::geom_point(data=theory, shape=21, stroke=NA, size=1,
                        fill=colors_homey$minor,
                        ggplot2::aes(x = semitone, y = -space_dissonance)) +
    ggplot2::geom_line(
      color=colors_homey$major,
      data=theory,
      ggplot2::aes(x = semitone, y = smooth_time,
                   group=1)) +
    ggplot2::geom_line(
      color=colors_homey$minor,
      data=theory,
      ggplot2::aes(x = semitone, y = smooth_space,
                   group=1)) +
    ggplot2::geom_text(data=per_plot_labels, color=colors_homey$neutral,
                       ggplot2::aes(x=-Inf,y=-Inf,label=label,
                                    vjust="inward",hjust="inward")) +
    ggplot2::xlab(NULL) +
    ggplot2::ylab(NULL) +
    ggplot2::facet_wrap(~space_uncertainty,ncol=ncols,dir='v',scales = "free_y") +
    ggplot2::scale_x_continuous(breaks = c(),
                                minor_breaks = 0:15) +
    theme_homey()
}

plot_semitone_codi_cochlear_amplifier_num_harmonics_wrap <- function(theory, experiment,
                                                                     black_vlines = c(), gray_vlines = c(),
                                                                     title, ncols = 12,
                                                                     include_points = TRUE) {

  per_plot_labels = tidyr::expand_grid(
    cochlear_amplifier_num_harmonics = theory$cochlear_amplifier_num_harmonics %>% unique
  )
  per_plot_labels$label = per_plot_labels %>%
    purrr::pmap_vec(\(cochlear_amplifier_num_harmonics) {
      paste0('   cochlear_amplifier_num_harmonics:', cochlear_amplifier_num_harmonics)
    })

  theory %>% ggplot2::ggplot(ggplot2::aes(x = semitone, y = smooth)) +
    ggplot2::geom_vline(xintercept = black_vlines, color = 'black') +
    ggplot2::geom_vline(xintercept = gray_vlines, color = 'gray44', linetype = 'dotted') +
    {if (include_points)
      ggplot2::geom_point(data = theory, shape = 21, stroke = NA, size = 1,
                          ggplot2::aes(x = semitone, y = z_score,
                                       fill = color_factor_mami(theory, 'majorness')))} +
    ggplot2::scale_fill_manual(values = color_values_homey(), guide = "none") +
    {if (!is.null(experiment)) {
      ggplot2::geom_line(
        data = experiment,
        color = colors_homey$neutral,
        ggplot2::aes(x = semitone, y = consonance))
    }} +
    ggplot2::geom_line(
      data = theory,
      ggplot2::aes(x = semitone, y = smooth,
                   group = 1,
                   color = color_factor_mami(theory, 'majorness'))) +
    ggplot2::scale_color_manual(values = color_values_homey(), guide = 'none') +
    ggplot2::geom_text(data = per_plot_labels, color = colors_homey$neutral,
                       ggplot2::aes(x = -Inf, y = -Inf, label = label,
                                    vjust = "inward", hjust = "inward")) +
    ggplot2::xlab(NULL) +
    ggplot2::ylab(NULL) +
    ggplot2::scale_x_continuous() +  # Automatically generate x-axis labels
    ggplot2::facet_wrap(~cochlear_amplifier_num_harmonics, ncol = ncols, dir = 'v',
                        scales = "free_y") +
    theme_homey()
}

plot_semitone_space_time_cochlear_amplifier_num_harmonics_wrap <- function(theory,
                                                                           black_vlines=c(), gray_vlines=c(),
                                                                           title,ncols=1) {
  per_plot_labels = tidyr::expand_grid(
    cochlear_amplifier_num_harmonics  = theory$cochlear_amplifier_num_harmonics  %>% unique
  )
  per_plot_labels$label = per_plot_labels %>%
    purrr::pmap_vec(\(cochlear_amplifier_num_harmonics) {
      paste0('   cochlear_amplifier_num_harmonics:', cochlear_amplifier_num_harmonics)
    })
  theory %>% ggplot2::ggplot(ggplot2::aes(x=semitone, y=smooth)) +
    ggplot2::geom_vline(xintercept = black_vlines, color='black') +
    ggplot2::geom_vline(xintercept = gray_vlines,color='gray44',linetype = 'dotted') +
    ggplot2::geom_point(data=theory, shape=21, stroke=NA, size=1,
                        fill=colors_homey$major,
                        ggplot2::aes(x = semitone, y = -time_dissonance)) +
    ggplot2::geom_point(data=theory, shape=21, stroke=NA, size=1,
                        fill=colors_homey$minor,
                        ggplot2::aes(x = semitone, y = -space_dissonance)) +
    ggplot2::geom_line(
      color=colors_homey$major,
      data=theory,
      ggplot2::aes(x = semitone, y = smooth_time,
                   group=1)) +
    ggplot2::geom_line(
      color=colors_homey$minor,
      data=theory,
      ggplot2::aes(x = semitone, y = smooth_space,
                   group=1)) +
    ggplot2::geom_text(data=per_plot_labels, color=colors_homey$neutral,
                       ggplot2::aes(x=-Inf,y=-Inf,label=label,
                                    vjust="inward",hjust="inward")) +
    ggplot2::xlab(NULL) +
    ggplot2::ylab(NULL) +
    ggplot2::facet_wrap(~cochlear_amplifier_num_harmonics,ncol=ncols,dir='v',scales = "free_y") +
    ggplot2::scale_x_continuous(breaks = c(),
                                minor_breaks = 0:15) +
    theme_homey()
}

plot_semitone_low_beating_cochlear_amplifier_num_harmonics_wrap <- function(theory,
                                                                            black_vlines=c(), gray_vlines=c(),
                                                                            title,ncols=1) {
  per_plot_labels = tidyr::expand_grid(
    cochlear_amplifier_num_harmonics  = theory$cochlear_amplifier_num_harmonics  %>% unique
  )
  per_plot_labels$label = per_plot_labels %>%
    purrr::pmap_vec(\(cochlear_amplifier_num_harmonics) {
      paste0('   cochlear_amplifier_num_harmonics:', cochlear_amplifier_num_harmonics)
    })
  theory %>% ggplot2::ggplot(ggplot2::aes(x=semitone, y=smooth)) +
    ggplot2::geom_vline(xintercept = black_vlines, color='black') +
    ggplot2::geom_vline(xintercept = gray_vlines,color='gray44',linetype = 'dotted') +
    ggplot2::geom_point(data=theory, shape=21, stroke=NA, size=1,
                        fill=colors_homey$green,
                        ggplot2::aes(x = semitone, y = low_beating)) +
    ggplot2::geom_text(data=per_plot_labels, color=colors_homey$neutral,
                       ggplot2::aes(x=-Inf,y=-Inf,label=label,
                                    vjust="inward",hjust="inward")) +
    ggplot2::xlab(NULL) +
    ggplot2::ylab(NULL) +
    ggplot2::facet_wrap(~cochlear_amplifier_num_harmonics,ncol=ncols,dir='v',scales = "free_y") +
    ggplot2::scale_x_continuous(breaks = c(),
                                minor_breaks = 0:15) +
    theme_homey()
}

plot_semitone_high_beating_cochlear_amplifier_num_harmonics_wrap <- function(theory,
                                                                             black_vlines=c(), gray_vlines=c(),
                                                                             title,ncols=1) {
  per_plot_labels = tidyr::expand_grid(
    cochlear_amplifier_num_harmonics  = theory$cochlear_amplifier_num_harmonics  %>% unique
  )
  per_plot_labels$label = per_plot_labels %>%
    purrr::pmap_vec(\(cochlear_amplifier_num_harmonics) {
      paste0('   cochlear_amplifier_num_harmonics:', cochlear_amplifier_num_harmonics)
    })
  theory %>% ggplot2::ggplot(ggplot2::aes(x=semitone, y=smooth)) +
    ggplot2::geom_vline(xintercept = black_vlines, color='black') +
    ggplot2::geom_vline(xintercept = gray_vlines,color='gray44',linetype = 'dotted') +
    ggplot2::geom_point(data=theory, shape=21, stroke=NA, size=1,
                        fill=colors_homey$fundamental,
                        ggplot2::aes(x = semitone, y = high_beating)) +
    ggplot2::geom_text(data=per_plot_labels, color=colors_homey$neutral,
                       ggplot2::aes(x=-Inf,y=-Inf,label=label,
                                    vjust="inward",hjust="inward")) +
    ggplot2::xlab(NULL) +
    ggplot2::ylab(NULL) +
    ggplot2::facet_wrap(~cochlear_amplifier_num_harmonics,ncol=ncols,dir='v',scales = "free_y") +
    ggplot2::scale_x_continuous(breaks = c(),
                                minor_breaks = 0:15) +
    theme_homey()
}

# Define the function to plot time vs. space as a 2D heatmap
plot_space_time_orig <- function(time_cycle_length, space_cycle_length, majorness = 0.0, chord_name = "Chord", time_range = 25, space_range = 25, resolution = 1000) {

  relative_f0 = 1/time_cycle_length
  relative_k0 = 1/space_cycle_length

  # Determine tonality based on majorness
  tonality <- if (majorness < 0) {
    'minor'
  } else if (majorness == 0) {
    'neutral'
  } else {
    'major'
  }

  # Select the color set based on tonality
  color_set <- saturation_colors_homey[[tonality]]

  # Generate a higher-resolution grid of time and space values
  time_values <- seq(0, time_range, length.out = resolution)
  space_values <- seq(0, space_range, length.out = resolution)

  # Create a data frame for the grid
  grid <- base::expand.grid(time = time_values, space = space_values)

  # Define a wave pattern as a function of time and space
  grid$amplitude <- base::sin(2 * base::pi * relative_f0 * grid$time - 2 * base::pi * relative_k0 * grid$space)

  # Plot using ggplot2 with selected color gradient and percentage labels
  ggplot2::ggplot(grid, ggplot2::aes(x = time, y = space, fill = amplitude)) +
    ggplot2::geom_tile() +
    ggplot2::scale_fill_gradient(low = color_set$lo, high = color_set$hi) +  # Dynamic color gradient
    ggplot2::scale_x_continuous(labels = scales::label_percent(scale = 1 / time_range)) +  # Percent label for time
    ggplot2::scale_y_continuous(labels = scales::label_percent(scale = 1 / space_range)) + # Percent label for space
    ggplot2::labs(
      x = "Time (%)",
      y = "Space (%)",
      title = bquote(.(chord_name) ~ ": Traveling Wave " ~ f[0] == .(sprintf("%.2f", relative_f0)) ~ "," ~ k[0] == .(sprintf("%.2f", relative_k0)))
    ) +
    ggplot2::coord_fixed(ratio = 1) +
    theme_homey()
}


# Define the function to plot time vs. space as a 2D heatmap
plot_space_time <- function(time_cycle_length, space_cycle_length, f0, k0, majorness = 0.0, chord_name = "Chord",
                            time_range = 25, space_range = 25, resolution = 1000) {

  # Define relative frequencies
  relative_f0 <- 1 / time_cycle_length
  relative_k0 <- 1 / space_cycle_length

  # Determine tonality based on majorness
  tonality <- if (majorness < 0) {
    'minor'
  } else if (majorness == 0) {
    'neutral'
  } else {
    'major'
  }

  # Select the color set based on tonality
  color_set <- saturation_colors_homey[[tonality]]

  # Generate a higher-resolution grid of time and space values
  time_values <- seq(0, time_range, length.out = resolution)
  space_values <- seq(0, space_range, length.out = resolution)

  # Create a data frame for the grid
  grid <- base::expand.grid(time = time_values, space = space_values)

  # Define a wave pattern as a function of time and space
  grid$amplitude <- base::cos(2 * base::pi * relative_f0 * grid$time - 2 * base::pi * relative_k0 * grid$space)

  # Define scaling factors to adjust the axis labels
  scale_time <- time_range / time_cycle_length * (1 / f0)
  scale_space <- space_range / space_cycle_length * (1 / k0)

  # Plot using ggplot2 with adjusted labels for time and space
  ggplot2::ggplot(grid, ggplot2::aes(x = time, y = space, fill = amplitude)) +
    ggplot2::geom_tile() +
    ggplot2::scale_fill_gradient(low = color_set$lo, high = color_set$hi) +
    ggplot2::scale_x_continuous(name = "Time (s)", labels = function(x) sprintf("%.3f", x * scale_time)) +
    ggplot2::scale_y_continuous(name = "Space (m)", labels = function(y) sprintf("%.3f", y * scale_space)) +
    ggplot2::labs(
      title = bquote(.(chord_name) ~ ": Traveling Wave " ~ f[0] == .(sprintf("%.2f", f0)) ~ "," ~ k[0] == .(sprintf("%.2f", k0)))
    ) +
    ggplot2::coord_fixed(ratio = 1) +
    theme_homey()
}
